// 文件说明：书架文件夹模型，保存嵌套层级和创建时间。
// 技术要点：UUID 标识、nullable 父目录、SQLite 时间戳序列化。

class ShelfFolder {
  const ShelfFolder({
    required this.id,
    required this.name,
    required this.parentId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'parent_id': parentId,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory ShelfFolder.fromMap(Map<String, Object?> map) => ShelfFolder(
    id: map['id']! as String,
    name: map['name']! as String,
    parentId: map['parent_id'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']! as int),
  );
}
