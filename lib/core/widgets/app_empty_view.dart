import 'package:flutter/material.dart';

class AppEmptyView extends StatelessWidget {
  const AppEmptyView({this.message = 'Chưa có nội dung.', super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Không có nội dung',
        excludeSemantics: true,
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
