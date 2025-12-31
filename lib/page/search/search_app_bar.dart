import 'package:flutter/material.dart';

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final void Function(String keyword)? onSearch;
  final String? keyword;

  const SearchAppBar({super.key, this.onSearch, this.keyword});

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  @override
  State<StatefulWidget> createState() {
    return _SearchAppBarState();
  }
}

class _SearchAppBarState extends State<SearchAppBar> {
  late final TextEditingController _controller;

  _SearchAppBarState();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.keyword);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: _controller,
        decoration: InputDecoration(
          isDense: true,
          hint: Text(
            "输入搜索内容",
            style: TextStyle(fontSize: 14),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
            borderSide: const BorderSide(
              color: Colors.black, // 边框颜色
              width: 1.0, // 边框宽度
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor, // 获得焦点时的边框颜色
              width: 2.0,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
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
            if (_controller.text.isNotEmpty) {
              widget.onSearch?.call(_controller.text);
            }
          },
          child: Text("搜索"),
        ),
      ],
      shadowColor: Theme.of(context).colorScheme.shadow,
    );
  }
}
