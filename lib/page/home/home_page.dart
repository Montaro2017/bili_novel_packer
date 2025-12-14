import 'package:bili_novel_packer/exception.dart';
import 'package:bili_novel_packer/novel_source/base/novel_model.dart';
import 'package:bili_novel_packer/novel_source/base/novel_source.dart';
import 'package:bili_novel_packer/page/home/novel_section_widget.dart';
import 'package:bili_novel_packer/page/search/search_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var sources = NovelSource.sources;
    return DefaultTabController(
      length: sources.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('BiliNovelPacker'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SearchPage(),
                  ),
                );
              },
              icon: Icon(Icons.search),
            ),
          ],
          bottom: TabBar(
            tabs: sources.map((s) => _toTab(s)).toList(),
          ),
        ),
        body: TabBarView(
          children: sources.map((s) => _NovelSourceHomeWidget(s)).toList(),
        ),
      ),
    );
  }

  Tab _toTab(NovelSource source) {
    return Tab(text: source.name);
  }
}

class _NovelSourceHomeWidget extends StatefulWidget {
  final NovelSource source;

  const _NovelSourceHomeWidget(this.source);

  @override
  State<StatefulWidget> createState() {
    return _NovelSourceHomeWidgetState();
  }
}

class _NovelSourceHomeWidgetState extends State<_NovelSourceHomeWidget>
    with AutomaticKeepAliveClientMixin {
  String? errorMsg;
  bool? retryAble;
  List<NovelSection>? sections;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (loading) {
      return _buildLoadingWidget();
    } else if (errorMsg != null) {
      return _buildErrorWidget();
    } else {
      return _buildExploreWidget();
    }
  }

  void _loadData() async {
    setState(() {
      loading = true;
    });
    try {
      var explore = await widget.source.explore();
      setState(() {
        sections = explore;
      });
    } on NotRetryableException catch (e) {
      setState(() {
        errorMsg = e.message;
        retryAble = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = e.toString();
        retryAble = true;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMsg ?? ''),
            if (retryAble ?? false)
              Padding(
                padding: EdgeInsetsGeometry.only(top: 10),
                child: ElevatedButton(
                  onPressed: () {
                    _loadData();
                  },
                  child: Text('重试'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreWidget() {
    return ListView.builder(
      itemCount: sections!.length,
      itemBuilder: (context, index) {
        var section = sections![index];
        var sectionWidget = NovelSectionWidget(
          source: widget.source,
          section: section,
          onTap: onTap,
        );
        if (index == 0) {
          return Padding(
            padding: EdgeInsetsGeometry.only(top: 8),
            child: sectionWidget,
          );
        } else {
          return sectionWidget;
        }
      },
    );
  }

  void onTap(Novel novel) {}

  @override
  bool get wantKeepAlive => true;
}
