import 'dart:collection';
import 'markdown_toc.dart';
import 'markdown_generator.dart';
import 'config/style_config.dart';
import 'config/widget_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

export 'dart:collection';
export 'markdown_toc.dart';
export 'markdown_generator.dart';
export 'config/style_config.dart';

class MarkdownWidget extends StatefulWidget {
  final String data;

  ///you can custom your widget by [widgetConfig]
  final WidgetConfig widgetConfig;

  ///you can use [styleConfig] to set default widget style, such as [pConfig.onTapLink]
  final StyleConfig styleConfig;

  final EdgeInsetsGeometry childMargin;

  ///if [controller] is not null, you can use [tocListener] to get current TOC index
  final TocController controller;

  ///show loading before data is ready
  final Widget loadingWidget;

  const MarkdownWidget({
    Key key,
    @required this.data,
    this.widgetConfig,
    this.styleConfig,
    this.childMargin,
    this.controller,
    this.loadingWidget,
  }) : super(key: key);

  @override
  _MarkdownWidgetState createState() => _MarkdownWidgetState();
}

class _MarkdownWidgetState extends State<MarkdownWidget> {
  MarkdownGenerator markdownGenerator;
  List<Widget> widgets = [];
  LinkedHashMap<int, Toc> tocList = LinkedHashMap();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  bool hasInitialed = false;

  @override
  void initState() {
    initialState();
    super.initState();
  }

  ///at the first time, we need to use isolate to create data to avoid UI thread stuck
  void initialState() {
    _MarkdownData _markdownData = _MarkdownData(
      data: widget.data,
      widgetConfig: widget.widgetConfig,
      styleConfig: widget.styleConfig,
      childMargin: widget.childMargin,
    );

    ///use a new isolate to create [MarkdownGenerator]
    compute(buildMarkdownGenerator, _markdownData).then((value) {
      markdownGenerator = value;
      tocList.addAll(markdownGenerator.tocList);
      widgets.addAll(markdownGenerator.widgets);
      if (widget.controller != null)
        itemPositionsListener.itemPositions.addListener(indexListener);
      refresh();
    });
  }

  ///when we've got the data, we need update data without setState() to avoid the flicker of the view
  void updateState() {
    markdownGenerator = MarkdownGenerator(
      data: widget.data,
      widgetConfig: widget.widgetConfig,
      styleConfig: widget.styleConfig,
      childMargin: widget.childMargin,
    );
    tocList.addAll(markdownGenerator.tocList);
    widgets.addAll(markdownGenerator.widgets);
    if (widget.controller != null)
      itemPositionsListener.itemPositions.addListener(indexListener);
  }

  Future<MarkdownGenerator> buildMarkdownGenerator(
      _MarkdownData markdownData) async {
    return MarkdownGenerator(
      data: markdownData.data,
      widgetConfig: markdownData.widgetConfig,
      styleConfig: markdownData.styleConfig,
      childMargin: markdownData.childMargin,
    );
  }

  void clearState() {
    tocList.clear();
    widgets.clear();
    markdownGenerator?.clear();
    markdownGenerator = null;
    if (widget.controller != null)
      itemPositionsListener.itemPositions.removeListener(indexListener);
    hasInitialed = false;
  }

  @override
  void dispose() {
    clearState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widgets.isEmpty ? buildLoadingWidget() : buildMarkdownWidget();
  }

  Center buildLoadingWidget() =>
      widget.loadingWidget ?? Center(child: CircularProgressIndicator());

  Widget buildMarkdownWidget() {
    return widget.controller == null
        ? ListView.builder(
            itemBuilder: (ctx, index) => widgets[index],
            itemCount: widgets.length,
          )
        : ScrollablePositionedList.builder(
            itemCount: widgets.length,
            itemBuilder: (context, index) => widgets[index],
            itemScrollController: widget?.controller?.scrollController,
            itemPositionsListener: itemPositionsListener,
          );
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  ///the listener of [ScrollablePositionedList]
  void indexListener() {
    bool needRefresh = false;
    final controller = widget?.controller;
    if (itemPositionsListener.itemPositions.value.isNotEmpty) {
      final current = itemPositionsListener.itemPositions.value.elementAt(0);
      final toc = tocList[current.index] ??
          tocList[current.index + 1] ??
          tocList[current.index - 1];
      if (toc != null && (controller?.setToc(toc) ?? false)) needRefresh = true;
    }
    if (!hasInitialed) {
      hasInitialed = true;
      if (controller?.setTocList(markdownGenerator.tocList) ?? false)
        needRefresh = true;
    }
    if (needRefresh) controller?.refresh();
  }

  @override
  void didUpdateWidget(MarkdownWidget oldWidget) {
    if (oldWidget.data != widget.data ||
        oldWidget.styleConfig != widget.styleConfig ||
        oldWidget.widgetConfig != widget.widgetConfig ||
        oldWidget.childMargin != widget.childMargin) {
      clearState();
      widget?.controller?.jumpTo(index: 0);
      updateState();
    }
    super.didUpdateWidget(widget);
  }
}

class _MarkdownData {
  final String data;
  final WidgetConfig widgetConfig;
  final StyleConfig styleConfig;
  final EdgeInsetsGeometry childMargin;

  _MarkdownData(
      {this.data, this.widgetConfig, this.styleConfig, this.childMargin});
}
