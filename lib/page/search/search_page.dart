import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }
}

class _SearchPageState extends State<SearchPage> {
  String? keyword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      body: keyword != null ? _SearchResult(keyword!) : null,
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    TextEditingController controller = TextEditingController();
    return AppBar(
      title: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "输入搜索内容",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0), // 可选：圆角
            borderSide: const BorderSide(
              color: Colors.black, // 边框颜色
              width: 1.0, // 边框宽度
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor, // 获得焦点时的边框颜色
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              color: Colors.grey, // 未获得焦点时的边框颜色
              width: 1.0,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              keyword = controller.text;
            });
          },
          child: Text("搜索"),
        ),
      ],
    );
  }
}

class _SearchResult extends StatefulWidget {
  final String keyword;

  const _SearchResult(this.keyword);

  @override
  State<StatefulWidget> createState() {
    return _SearchResultState();
  }
}

class _SearchResultState extends State<_SearchResult> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(widget.keyword));
  }
}
