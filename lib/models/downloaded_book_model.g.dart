// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloaded_book_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DownloadedBookAdapter extends TypeAdapter<DownloadedBook> {
  @override
  final int typeId = 0;

  @override
  DownloadedBook read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadedBook(
      bookId: fields[0] as int,
      title: fields[1] as String,
      author: fields[2] as String,
      department: fields[3] as String,
      subject: fields[4] as String,
      localFilePath: fields[5] as String,
      downloadDate: fields[6] as DateTime,
      fileSizeBytes: fields[7] as int,
      accessType: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedBook obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.bookId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.department)
      ..writeByte(4)
      ..write(obj.subject)
      ..writeByte(5)
      ..write(obj.localFilePath)
      ..writeByte(6)
      ..write(obj.downloadDate)
      ..writeByte(7)
      ..write(obj.fileSizeBytes)
      ..writeByte(8)
      ..write(obj.accessType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedBookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
