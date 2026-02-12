import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_consumer.dart';
import '../../../../core/error_handling/exceptions.dart';

/// Remote data source for chat API
abstract class RemoteChatDatasource {
  Future<Either<NetworkException, String>> sendMessage(String query);
}

class RemoteChatDatasourceImpl implements RemoteChatDatasource {
  final ApiConsumer apiConsumer;

  RemoteChatDatasourceImpl({required this.apiConsumer});

  @override
  Future<Either<NetworkException, String>> sendMessage(String query) async {
    try {
      StringBuffer contentBuffer = StringBuffer();
      StringBuffer lineBuffer = StringBuffer();

      // Process the stream of data
      await for (final chunk in apiConsumer.postStream(
        '/chat/stream',
        // '/stream/5',
        // '/drip?numbytes=50&duration=5&delay=1&code=200',
        body: {'query': query},
        options: Options(
          // responseType: ResponseType.stream,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          },
        ),
      )) {
        print('chunk*** $chunk');
        // Accumulate chunks into lines
        lineBuffer.write(chunk);
        final bufferContent = lineBuffer.toString();

        // Process complete lines (ending with \n)
        final lines = bufferContent.split('\n');
        // Keep the last incomplete line in the buffer
        lineBuffer.clear();
        if (bufferContent.endsWith('\n')) {
          // All lines are complete
          for (final line in lines) {
            _processSSELine(line.trim(), contentBuffer);
          }
        } else {
          // Last line is incomplete, keep it in buffer
          for (int i = 0; i < lines.length - 1; i++) {
            _processSSELine(lines[i].trim(), contentBuffer);
          }
          lineBuffer.write(lines.last);
        }
      }

      // Process any remaining data in the buffer
      if (lineBuffer.isNotEmpty) {
        _processSSELine(lineBuffer.toString().trim(), contentBuffer);
      }

      final fullContent = contentBuffer.toString();
      if (fullContent.isNotEmpty) {
        return Right(fullContent);
      } else {
        return Left(
          NetworkException(
            message: 'Invalid response format: No content found',
          ),
        );
      }
    } on NetworkException catch (e) {
      return Left(e);
    } catch (e) {
      return Left(
        NetworkException(message: 'Error processing stream: ${e.toString()}'),
      );
    }
  }

  void _processSSELine(String line, StringBuffer contentBuffer) {
    if (line.startsWith('data: ')) {
      final jsonStr = line.substring(6).trim(); // Remove "data: " prefix
      if (jsonStr.isNotEmpty) {
        try {
          final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
          // Extract content if available
          if (jsonData.containsKey('content')) {
            contentBuffer.write(jsonData['content']);
          }
        } catch (e) {
          // Skip invalid JSON lines (like chat_id lines or other metadata)
          // This is expected for some SSE events
        }
      }
    }
  }
}
