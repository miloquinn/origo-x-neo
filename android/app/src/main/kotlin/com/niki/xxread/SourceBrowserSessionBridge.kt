package com.niki.xxread

import android.app.Activity
import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import android.graphics.Color
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.platform.PlatformViewRegistry
import org.json.JSONObject
import org.json.JSONTokener
import java.io.File

class SourceBrowserSessionBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
    platformViews: PlatformViewRegistry,
) {
    companion object {
        private const val CHANNEL = "com.niki.xxread/source_browser_session"
        private const val OPEN_REQUEST_CODE = 59143
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private val replyMessenger = Messenger(ReplyHandler())
    private val pendingLoads = linkedMapOf<String, PendingLoad>()
    private val outbound = ArrayDeque<Message>()
    private var service: Messenger? = null
    private var bound = false
    private var pendingOpen: PendingOpen? = null
    private var pendingClear: MethodChannel.Result? = null

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            service = binder?.let(::Messenger)
            while (outbound.isNotEmpty()) service?.send(outbound.removeFirst())
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            service = null
            pendingClear?.error("service_disconnected", "Source browser service disconnected.", null)
            pendingClear = null
            pendingLoads.forEach { (_, pending) ->
                pending.requestFile.delete()
                pending.result.error("service_disconnected", "Source browser service disconnected.", null)
            }
            pendingLoads.clear()
            outbound.clear()
        }
    }

    init {
        platformViews.registerViewFactory(
            "com.niki.xxread/source_browser_content",
            SourceBrowserContentViewFactory(activity, messenger),
        )
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "open" -> open(call.arguments as? Map<*, *>, result)
                "load" -> load(call.arguments as? Map<*, *>, result)
                "clear" -> clear(call.argument<String>("sourceId"), result)
                "cancel" -> cancel(call.argument<String>("requestId"), result)
                else -> result.notImplemented()
            }
        }
        bound = activity.bindService(
            Intent(activity, SourceBrowserSessionService::class.java),
            connection,
            Context.BIND_AUTO_CREATE,
        )
    }

    private fun open(arguments: Map<*, *>?, result: MethodChannel.Result) {
        if (pendingOpen != null) {
            result.error("busy", "Another source browser login is already open.", null)
            return
        }
        val sourceId = arguments?.get("sourceId")?.toString().orEmpty()
        val url = arguments?.get("url")?.toString().orEmpty()
        if (sourceId.isBlank() || !isSafeSourceBrowserUrl(url)) {
            result.error("invalid_request", "sourceId and URL are required.", null)
            return
        }
        val requestDir = File(activity.cacheDir, "source_browser_session").apply { mkdirs() }
        val requestFile = File(requestDir, "open-request-${System.nanoTime()}.json")
        try {
            requestFile.writeText(JSONObject(arguments ?: emptyMap<Any, Any>()).toString())
        } catch (error: Exception) {
            requestFile.delete()
            result.error("request_failed", error.message ?: "Browser login request could not be prepared.", null)
            return
        }
        pendingOpen = PendingOpen(result, requestFile)
        val intent = Intent(activity, SourceBrowserSessionActivity::class.java).apply {
            putExtra(SourceBrowserSessionActivity.EXTRA_REQUEST_FILE, requestFile.absolutePath)
        }
        try {
            activity.startActivityForResult(intent, OPEN_REQUEST_CODE)
        } catch (error: Exception) {
            pendingOpen = null
            requestFile.delete()
            result.error("unavailable", error.message ?: "Source browser login could not be opened.", null)
        }
    }

    private fun load(arguments: Map<*, *>?, result: MethodChannel.Result) {
        val args = arguments ?: emptyMap<Any, Any>()
        val sourceId = args["sourceId"]?.toString().orEmpty()
        val requestId = args["requestId"]?.toString().orEmpty()
        val url = args["url"]?.toString().orEmpty()
        if (sourceId.isBlank() || requestId.isBlank() || !isSafeSourceBrowserUrl(url)) {
            result.error("invalid_request", "sourceId, requestId, and URL are required.", null)
            return
        }
        if (pendingLoads.containsKey(requestId)) {
            result.error("duplicate_request", "Browser session request ID is already active.", null)
            return
        }
        val requestDir = File(activity.cacheDir, "source_browser_session").apply { mkdirs() }
        val requestFile = File(requestDir, "request-${System.nanoTime()}.json")
        try {
            val normalized = linkedMapOf<String, Any?>(
                "sourceId" to sourceId,
                "requestId" to requestId,
                "url" to url,
                "headers" to (args["headers"] ?: emptyMap<String, String>()),
                "session" to (args["session"] ?: emptyMap<String, Any?>()),
                "method" to (args["method"]?.toString() ?: "GET"),
                "body" to (args["body"]?.toString() ?: ""),
                "webJs" to args["webJs"]?.toString(),
                "html" to args["html"]?.toString(),
                "timeoutMs" to ((args["timeoutMs"] as? Number)?.toLong() ?: 15_000L),
            )
            requestFile.writeText(JSONObject(normalized).toString())
        } catch (error: Exception) {
            requestFile.delete()
            result.error("request_failed", error.message ?: "Browser request could not be prepared.", null)
            return
        }
        pendingLoads[requestId] = PendingLoad(result, requestFile)
        send(
            Message.obtain(null, SourceBrowserSessionService.MSG_LOAD).apply {
                replyTo = replyMessenger
                data = Bundle().apply {
                    putString(SourceBrowserSessionService.KEY_REQUEST_ID, requestId)
                    putString(SourceBrowserSessionService.KEY_REQUEST_FILE, requestFile.absolutePath)
                }
            },
        )
    }

    private fun clear(sourceId: String?, result: MethodChannel.Result) {
        if (sourceId.isNullOrBlank()) {
            result.error("invalid_request", "sourceId is required.", null)
            return
        }
        if (pendingClear != null) {
            result.error("busy", "A browser session clear is already active.", null)
            return
        }
        pendingClear = result
        send(
            Message.obtain(null, SourceBrowserSessionService.MSG_CLEAR).apply {
                replyTo = replyMessenger
                data = Bundle().apply { putString(SourceBrowserSessionService.KEY_SOURCE_ID, sourceId) }
            },
        )
    }

    private fun cancel(requestId: String?, result: MethodChannel.Result) {
        if (requestId.isNullOrBlank() || !pendingLoads.containsKey(requestId)) {
            result.success(false)
            return
        }
        send(
            Message.obtain(null, SourceBrowserSessionService.MSG_CANCEL).apply {
                replyTo = replyMessenger
                data = Bundle().apply { putString(SourceBrowserSessionService.KEY_REQUEST_ID, requestId) }
            },
        )
        result.success(true)
    }

    private fun send(message: Message) {
        val target = service
        if (target == null) outbound.addLast(message) else target.send(message)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != OPEN_REQUEST_CODE) return false
        val pending = pendingOpen ?: return true
        pendingOpen = null
        pending.requestFile.delete()
        if (resultCode != Activity.RESULT_OK || data == null) {
            pending.result.error(
                data?.getStringExtra("errorCode") ?: "cancelled",
                data?.getStringExtra("errorMessage") ?: "Source browser login was cancelled.",
                null,
            )
            return true
        }
        returnResultFile(data.getStringExtra(SourceBrowserSessionActivity.RESULT_FILE), pending.result)
        return true
    }

    private inner class ReplyHandler : Handler(Looper.getMainLooper()) {
        override fun handleMessage(message: Message) {
            val requestId = message.data.getString(SourceBrowserSessionService.KEY_REQUEST_ID)
            if (requestId == null && pendingClear != null) {
                val clearResult = pendingClear
                pendingClear = null
                if (message.what == SourceBrowserSessionService.MSG_SUCCESS) clearResult?.success(null)
                else clearResult?.error(
                    message.data.getString(SourceBrowserSessionService.KEY_ERROR_CODE) ?: "clear_failed",
                    message.data.getString(SourceBrowserSessionService.KEY_ERROR_MESSAGE),
                    null,
                )
                return
            }
            val pending = requestId?.let(pendingLoads::remove) ?: return
            pending.requestFile.delete()
            if (message.what == SourceBrowserSessionService.MSG_SUCCESS) {
                returnResultFile(message.data.getString(SourceBrowserSessionService.KEY_RESULT_FILE), pending.result)
            } else {
                pending.result.error(
                    message.data.getString(SourceBrowserSessionService.KEY_ERROR_CODE) ?: "load_failed",
                    message.data.getString(SourceBrowserSessionService.KEY_ERROR_MESSAGE),
                    null,
                )
            }
        }
    }

    private fun returnResultFile(path: String?, result: MethodChannel.Result) {
        val file = path?.let(::File)
        if (file == null || !file.isFile) {
            result.error("result_failed", "Browser session result is missing.", null)
            return
        }
        try {
            result.success(jsonToPlatform(JSONObject(file.readText())))
        } catch (error: Exception) {
            result.error("result_failed", error.message ?: "Browser session result is invalid.", null)
        } finally {
            file.delete()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pendingOpen?.requestFile?.delete()
        pendingOpen?.result?.error("disposed", "Source browser session closed.", null)
        pendingOpen = null
        pendingClear?.error("disposed", "Source browser session closed.", null)
        pendingClear = null
        pendingLoads.forEach { (_, pending) ->
            pending.requestFile.delete()
            pending.result.error("disposed", "Source browser session closed.", null)
        }
        pendingLoads.clear()
        outbound.clear()
        if (bound) activity.unbindService(connection)
        bound = false
        service = null
    }

    private data class PendingLoad(val result: MethodChannel.Result, val requestFile: File)
    private data class PendingOpen(val result: MethodChannel.Result, val requestFile: File)
}

private class SourceBrowserContentViewFactory(
    private val context: Context,
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView =
        SourceBrowserContentPlatformView(this.context, messenger, viewId, args as? Map<*, *>)
}

@SuppressLint("SetJavaScriptEnabled")
private class SourceBrowserContentPlatformView(
    private val context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    private val args: Map<*, *>?,
) : PlatformView {
    private val sourceId = args?.get("sourceId")?.toString().orEmpty()
    private val url = args?.get("url")?.toString().orEmpty()
    private val sourceUrl = args?.get("sourceUrl")?.toString().orEmpty().ifBlank { url }
    private val owner = "content:$viewId:$sourceId"
    private val headers = (args?.get("headers") as? Map<*, *>)?.entries?.associate {
        it.key.toString() to it.value.toString()
    }.orEmpty()
    private val html = args?.get("html")?.toString()?.takeIf(String::isNotEmpty)
    private val preloadJs = args?.get("preloadJs")?.toString()?.takeIf(String::isNotBlank)
    private val tracker = SourceBrowserSessionTracker(
        SourceBrowserSession.fromJson(JSONObject(args?.get("session") as? Map<*, *> ?: emptyMap<Any, Any>()).toString()),
    )
    private val channel = MethodChannel(messenger, "com.niki.xxread/source_browser_content/$viewId")
    private val webView = WebView(context)
    private var acquired = false
    private var hydrating = false
    private var hydrationIndex = 0
    private val hydration = tracker.hydrationOrigins()
    private var disposed = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "reload" -> { webView.reload(); result.success(null) }
                "capture" -> capture(false, result)
                "close" -> capture(true, result)
                "completeScriptRequest" -> {
                    completeScriptRequest(call.arguments as? Map<*, *>)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        webView.setBackgroundColor(Color.TRANSPARENT)
        webView.isVerticalScrollBarEnabled = true
        configureSourceBrowserWebView(webView, headers)
        webView.addJavascriptInterface(ContentJavascriptBridge(::handleBridgePayload), "xxreadContentBridge")
        webView.webChromeClient = object : WebChromeClient() {
            override fun onProgressChanged(view: WebView, progress: Int) {
                channel.invokeMethod("loading", progress < 100)
            }
        }
        webView.webViewClient = object : WebViewClient() {
            override fun onPageStarted(view: WebView, nextUrl: String, favicon: android.graphics.Bitmap?) {
                if (!hydrating) tracker.observeCookies(nextUrl)
                channel.invokeMethod("loading", true)
            }

            override fun onPageFinished(view: WebView, finishedUrl: String) {
                if (hydrating) {
                    hydrationIndex++
                    hydrateNextOrLoad()
                    return
                }
                tracker.observeCookies(finishedUrl)
                view.evaluateJavascript(tracker.captureStorageScript()) { tracker.mergeStorage(it) }
                installBridge(view)
                channel.invokeMethod("loading", false)
                emitSnapshot()
            }

            override fun onReceivedError(view: WebView, request: WebResourceRequest, error: android.webkit.WebResourceError) {
                if (request.isForMainFrame) channel.invokeMethod("error", error.description.toString())
            }

            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                val scheme = request.url.scheme?.lowercase()
                return scheme !in setOf("http", "https", "about", "blob", "data", "javascript")
            }

            override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? {
                tracker.recordVisitedUrl(request.url.toString())
                return null
            }
        }

        if (sourceId.isBlank() || !isSafeSourceBrowserUrl(url) ||
            !SourceBrowserSessionRuntime.supportsIsolatedDataDirectory
        ) {
            channel.invokeMethod("error", "Embedded source browser is unavailable for this request.")
        } else {
            acquired = SourceBrowserSessionRuntime.acquire(owner, sourceId) {
                webView.post { channel.invokeMethod("error", "Another source browser session replaced this view.") }
            }
            if (!acquired) {
                channel.invokeMethod("error", "Another source browser session is active.")
            } else {
                SourceBrowserSessionRuntime.clearStorage {
                    if (!disposed) tracker.restoreCookies { hydrateNextOrLoad() }
                }
            }
        }
    }

    override fun getView(): View = webView

    private fun hydrateNextOrLoad() {
        if (disposed) return
        if (hydrationIndex < hydration.size) {
            hydrating = true
            val (origin, values) = hydration[hydrationIndex]
            webView.loadDataWithBaseURL("$origin/", tracker.hydrationHtml(values), "text/html", "UTF-8", null)
            return
        }
        hydrating = false
        val navigationHeaders = headers.filterKeys {
            !it.equals("cookie", true) && !it.equals("user-agent", true)
        }
        if (html != null) webView.loadDataWithBaseURL(url, html, "text/html", "UTF-8", null)
        else webView.loadUrl(url, navigationHeaders)
    }

    private fun installBridge(view: WebView) {
        view.evaluateJavascript(contentBridgeScript(sourceUrl), null)
        preloadJs?.let { view.evaluateJavascript(it, null) }
        applyColors(view)
    }

    private fun applyColors(view: WebView) {
        val background = (args?.get("backgroundColor") as? Number)?.toLong()
        val text = (args?.get("textColor") as? Number)?.toLong()
        if (background == null && text == null) return
        val css = buildString {
            append(":root{color-scheme:")
            append(if (args.get("isDark") == true) "dark" else "light")
            append(";}")
            if (background != null) append("html,body{background-color:${colorCss(background)};}")
            if (text != null) append("body{color:${colorCss(text)};}")
        }
        val script = "(function(){var s=document.getElementById('__xxreadTheme');if(!s){s=document.createElement('style');s.id='__xxreadTheme';document.head.appendChild(s);}s.textContent=${JSONObject.quote(css)};})();"
        view.evaluateJavascript(script, null)
    }

    private fun capture(close: Boolean, result: MethodChannel.Result) {
        if (disposed) {
            result.error("disposed", "Source browser view is closed.", null)
            return
        }
        snapshot { value ->
            result.success(value)
            if (close) webView.stopLoading()
        }
    }

    private fun emitSnapshot() = snapshot { channel.invokeMethod("sessionSnapshot", it) }

    private fun snapshot(done: (Map<String, Any?>) -> Unit) {
        if (disposed || hydrating) return
        val current = webView.url ?: url
        tracker.observeCookies(current)
        webView.evaluateJavascript(tracker.captureStorageScript()) { storage ->
            tracker.mergeStorage(storage)
            webView.evaluateJavascript(
                "(function(){return document.documentElement ? document.documentElement.outerHTML : (document.body ? document.body.innerHTML : '');})()",
            ) { encoded ->
                val body = try { JSONTokener(encoded ?: "null").nextValue() as? String ?: "" } catch (_: Exception) { "" }
                done(mapOf("body" to body, "finalUrl" to current, "session" to tracker.sessionMap()))
            }
        }
    }

    private fun handleBridgePayload(raw: String) {
        webView.post {
            val payload = try { JSONObject(raw) } catch (_: Exception) { return@post }
            val method = payload.optString("method")
            val value = payload.opt("value")
            when (method) {
                "close", "dismiss" -> channel.invokeMethod("closeRequested", null)
                "refreshContent" -> channel.invokeMethod("refreshContent", value?.toString().orEmpty())
                "copy" -> channel.invokeMethod("copy", value?.toString().orEmpty())
                "toast", "longToast" -> channel.invokeMethod("toast", value?.toString().orEmpty())
                "request" -> channel.invokeMethod("scriptRequest", jsonToPlatform(payload))
            }
        }
    }

    private fun completeScriptRequest(raw: Map<*, *>?) {
        val id = raw?.get("id")?.toString().orEmpty()
        if (id.isEmpty()) return
        val script = if (raw?.containsKey("error") == true) {
            "window.__xxreadBridgeReject(${JSONObject.quote(id)},${JSONObject.quote(raw["error"]?.toString().orEmpty())});"
        } else {
            val value = JSONObject.wrap(raw?.get("value"))
            "window.__xxreadBridgeResolve(${JSONObject.quote(id)},${value?.toString() ?: "null"});"
        }
        webView.evaluateJavascript(script, null)
    }

    override fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        webView.stopLoading()
        webView.removeJavascriptInterface("xxreadContentBridge")
        webView.webChromeClient = null
        webView.webViewClient = WebViewClient()
        webView.destroy()
        if (acquired) {
            SourceBrowserSessionRuntime.clearStorage { SourceBrowserSessionRuntime.release(owner) }
            acquired = false
        }
    }

    private fun colorCss(value: Long): String = "#%08x".format(value).let { "#${it.substring(3)}${it.substring(1, 3)}" }
}

private class ContentJavascriptBridge(private val dispatch: (String) -> Unit) {
    @JavascriptInterface fun postMessage(payload: String) = dispatch(payload)
}

private fun contentBridgeScript(sourceUrl: String): String = """
    (function(){
      if (window.__xxreadBridgeInstalled) return;
      window.__xxreadBridgeInstalled = true;
      var pending = Object.create(null), serial = 0;
      function post(payload){ try { window.xxreadContentBridge.postMessage(JSON.stringify(payload)); } catch (_) {} }
      function request(method,args,id){
        id = id || ('web-' + Date.now() + '-' + (++serial));
        return new Promise(function(resolve,reject){ pending[id]={resolve:resolve,reject:reject}; post({method:'request',id:id,methodName:method,arguments:Array.prototype.slice.call(args||[])}); });
      }
      window.__xxreadBridgeResolve=function(id,value){if(pending[id]){pending[id].resolve(value);delete pending[id];}};
      window.__xxreadBridgeReject=function(id,error){if(pending[id]){pending[id].reject(new Error(String(error)));delete pending[id];}};
      var java = window.java || {};
      java.refreshContent=function(value){post({method:'refreshContent',value:String(value==null?'':value)});};
      java.close=java.dismiss=java.closeBottomView=function(){post({method:'close'});};
      java.copy=function(value){post({method:'copy',value:String(value==null?'':value)});};
      java.toast=function(value){post({method:'toast',value:String(value==null?'':value)});};
      java.longToast=java.toast;
      var unsupportedMethods=['webViewGetSource','createSignHex','importScript'];
      function unsupported(method){return Promise.reject(new Error('Unsupported source page method: java.'+method));}
      function normalizeMethod(method){method=String(method);if(method==='run')return 'eval';if(/Await$/.test(method))return 'java.'+method.replace(/Await$/,'');return method.indexOf('.')>=0?method:'java.'+method;}
      java.request=function(method,args,id){var name=String(method).replace(/Await$/,'').replace(/^java\./,'');return unsupportedMethods.indexOf(name)>=0?unsupported(name):request(normalizeMethod(method),args,id);};
      java.ajaxAwait=function(){return request('java.ajax',arguments);};
      java.ajax=java.ajaxAwait;
      window.java=java;
      window.run=function(code){return request('eval',[String(code)]);};
      ['ajaxAwait','connectAwait','getAwait','headAwait','postAwait','webViewAwait','decryptStrAwait','encryptBase64Await','encryptHexAwait','getStringAwait'].forEach(function(name){window[name]=function(){return java.request(name,arguments);};});
      ['webViewGetSourceAwait','createSignHexAwait','importScriptAwait'].forEach(function(name){window[name]=function(){return unsupported(name.replace(/Await$/,''));};});
      window.source=window.source||{bookSourceUrl:${JSONObject.quote(sourceUrl)}};
      window.cache=window.cache||{get:function(key){return request('cache.get',[key]);},put:function(key,value){return request('cache.put',[key,value]);}};
    })();
""".trimIndent()
