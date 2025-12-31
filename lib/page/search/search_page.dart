import 'package:bili_novel_packer/exception.dart';
import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/page/detail/detail_page.dart';
import 'package:bili_novel_packer/page/search/search_app_bar.dart';
import 'package:bili_novel_packer/widget/novel_card_grid.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }
}

class _SearchPageState extends State<SearchPage> {
  NovelSource source = NovelSource.sources.first;
  SearchIterator<Novel>? _searchIterator;
  List<Novel> _novels = [];
  bool _loading = false;
  bool _moreLoading = false;
  dynamic _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        onSearch: _doSearch,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sourceChips(),
        _searchResult(),
      ],
    );
  }

  Widget _sourceChips() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 24, 0),
      child: Wrap(
        alignment: WrapAlignment.start,
        children: NovelSource.sources.map((s) => _buildSourceChip(s)).toList(),
      ),
    );
  }

  Widget _searchResult() {
    ScrollController scrollController = ScrollController();
    scrollController.addListener(() {
      // 计算是否接近底部
      if (scrollController.position.pixels >=
              scrollController.position.maxScrollExtent - 200 &&
          !_loading) {
        _loadNext(); // 触发加载
      }
    });
    return Expanded(
      child: _error != null
          ? _buildErrorWidget()
          : _loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  if (_novels.isNotEmpty)
                    NovelCardGridView(
                      source: source,
                      novels: _novels,
                      onTap: (novel) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                DetailPage(source: source, novelId: novel.id),
                          ),
                        );
                      },
                    ),
                  if (_moreLoading) _moreLoadingWidget(),
                ],
              ),
            ),
    );
  }

  Widget _buildSourceChip(NovelSource source) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FilterChip(
        label: Text(source.name),
        selected: this.source == source,
        onSelected: (b) {
          setState(() {
            this.source = source;
          });
        },
      ),
    );
  }

  void _doSearch(String keyword) async {
    setState(() {
      _error = null;
      _novels = [];
      _loading = true;
    });
    try {
      _searchIterator = source.search(keyword);
      if (_searchIterator!.hasNext) {
        _novels.addAll(await _searchIterator!.next());
      }
    } catch (e) {
      setState(() {
        _error = e;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _loadNext() async {
    if (_moreLoading) {
      return;
    }
    _moreLoading = true;
    setState(() {
      _error = null;
    });
    try {
      if (_searchIterator != null && _searchIterator!.hasNext) {
        _novels.addAll(await _searchIterator!.next());
      }
    } catch (e) {
      setState(() {
        _error = e;
      });
    } finally {
      setState(() {
        _moreLoading = false;
      });
    }
  }

  Widget _moreLoadingWidget() {
    return Padding(
      padding: EdgeInsetsGeometry.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    String msg = _error.toString();
    bool retryable = true;
    if (_error is NotRetryableException) {
      msg = _error.message;
      retryable = false;
    } else {
      msg = _error.toString();
    }
    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(msg),
            if (retryable)
              Padding(
                padding: EdgeInsetsGeometry.only(top: 10),
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('重试'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
