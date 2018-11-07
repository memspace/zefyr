import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator;

import 'editable_box.dart';

// md5 加密
String generateMd5(String data) {
  var content = new Utf8Encoder().convert(data);
  var digest = md5.convert(content);
  // 这里其实就是 digest.toString()
  return hex.encode(digest.bytes);
}

typedef ZefyrGoodsModel OnSelectGoods(ZefyrGoodsModel goods);

/// 商品组件
/// {"insert":"​","attributes":{"embed":{"type":"goods", "source":{"id":575403694783,"thumbs":["//t00img.yangkeduo.com/goods/images/2018-10-14/4f329fb8fdb5590e1ca673e6d614f242.jpeg?imageMogr2/strip|imageView2/2/w/1300/q/80", "//t00img.yangkeduo.com/goods/images/2018-10-14/cb480dc6e49f3ec9f7e2febf8b85292a.jpeg?imageMogr2/strip|imageView2/2/w/1300/q/80", "//t00img.yangkeduo.com/goods/images/2018-10-14/c224a1fe13a5ce02bc506e9279f6f3ef.jpeg?imageMogr2/strip|imageView2/2/w/1300/q/80"],"platform":"tb","title": "HKH补水美肌护肤【四件套】","content": ""}}}}
///
class ZefyrGoodsModel {
  int id;
  List<String> thumbs;
  String platform;
  String title;
  String subtitle;
  String content;
  String price;
  int volume;

  ZefyrGoodsModel(
      {this.id,
      this.thumbs,
      this.platform,
      this.title,
      this.subtitle,
      this.content,
      this.price,
      this.volume});

  ZefyrGoodsModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    thumbs = json['thumbs'].cast<String>();
    platform = json['platform'];
    title = json['title'];
    subtitle = json['subtitle'];
    content = json['content'];
    price = json['price'];
    volume = json['volume'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['thumbs'] = this.thumbs;
    data['platform'] = this.platform;
    data['title'] = this.title;
    data['subtitle'] = this.subtitle;
    data['content'] = this.content;
    data['price'] = this.price;
    data['volume'] = this.volume;
    return data;
  }
}

class ZefyrGoods extends StatefulWidget {
  const ZefyrGoods({Key key, @required this.node})
      : super(key: key);

  // 是否编辑状态
  final EmbedNode node;

  @override
  _ZefyrGoodsState createState() => _ZefyrGoodsState();
}

class _ZefyrGoodsState extends State<ZefyrGoods> {
  String get imageSource {
    EmbedAttribute attribute = widget.node.style.get(NotusAttribute.embed);
    return attribute.value['source'];
  }

  @override
  Widget build(BuildContext context) {
    return _EditableGoods(
        child: Container(
          height: 132.0,
          width: 130.0,
          alignment: Alignment.center,
          color: Colors.amberAccent,
          child: GestureDetector(
            onTap: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    final TextEditingController _controller =
                        new TextEditingController();
                    return Scaffold(
                      body: Column(
                        children: <Widget>[
                          TextField(
                            controller: _controller,
                            autofocus: true,
                            decoration: new InputDecoration(
                              hintText: '搜索商品标题、链接【淘宝、天猫、拼多多】',
                            ),
                          ),
                          Align(
                            child: Container(),
                          )
                        ],
                      ),
                    );
                  });
            },
            child: Container(
              child: Text(
                "编辑",
                style: TextStyle(color: Colors.white),
              ),
              color: Colors.black,
              padding: EdgeInsets.all(20.0),
            ),
          ),
        ),
        node: widget.node);
  }
}

class _EditableGoods extends SingleChildRenderObjectWidget {
  _EditableGoods({@required Widget child, @required this.node})
      : assert(node != null),
        super(child: child);

  final EmbedNode node;

  @override
  RenderEditableGoods createRenderObject(BuildContext context) {
    return new RenderEditableGoods(node: node);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderEditableGoods renderObject) {
    renderObject..node = node;
  }
}

class RenderEditableGoods extends RenderBox
    with RenderObjectWithChildMixin<RenderBox>, RenderProxyBoxMixin<RenderBox>
    implements RenderEditableBox {
  static const kPaddingBottom = 24.0;

  RenderEditableGoods({
    RenderImage child,
    @required EmbedNode node,
  }) : _node = node {
    this.child = child;
  }

  @override
  EmbedNode get node => _node;
  EmbedNode _node;
  void set node(EmbedNode value) {
    _node = value;
  }

  // TODO: Customize caret height offset instead of adjusting here by 2px.
  @override
  double get preferredLineHeight => size.height - kPaddingBottom + 2.0;

  @override
  SelectionOrder get selectionOrder => SelectionOrder.foreground;

  @override
  TextSelection getLocalSelection(TextSelection documentSelection) {
    if (!intersectsWithSelection(documentSelection)) return null;

    int nodeBase = node.documentOffset;
    int nodeExtent = nodeBase + node.length;
    int base = math.max(0, documentSelection.baseOffset - nodeBase);
    int extent =
        math.min(documentSelection.extentOffset, nodeExtent) - nodeBase;
    return documentSelection.copyWith(baseOffset: base, extentOffset: extent);
  }

  @override
  List<ui.TextBox> getEndpointsForSelection(TextSelection selection) {
    TextSelection local = getLocalSelection(selection);
    if (local.isCollapsed) {
      final dx = local.extentOffset == 0 ? _childOffset.dx : size.width;
      return [
        new ui.TextBox.fromLTRBD(
            dx, 0.0, dx, size.height - kPaddingBottom, TextDirection.ltr),
      ];
    }

    final rect = _childRect;
    return [
      new ui.TextBox.fromLTRBD(
          rect.left, rect.top, rect.left, rect.bottom, TextDirection.ltr),
      new ui.TextBox.fromLTRBD(
          rect.right, rect.top, rect.right, rect.bottom, TextDirection.ltr),
    ];
  }

  @override
  TextPosition getPositionForOffset(Offset offset) {
    int position = _node.documentOffset;

    if (offset.dx > size.width / 2) {
      position++;
    }
    return new TextPosition(offset: position);
  }

  @override
  TextRange getWordBoundary(TextPosition position) {
    final start = _node.documentOffset;
    return new TextRange(start: start, end: start + 1);
  }

  @override
  bool intersectsWithSelection(TextSelection selection) {
    final int base = node.documentOffset;
    final int extent = base + node.length;
    return base <= selection.extentOffset && selection.baseOffset <= extent;
  }

  @override
  Offset getOffsetForCaret(TextPosition position, Rect caretPrototype) {
    final pos = position.offset - node.documentOffset;
    Offset caretOffset = _childOffset - new Offset(kHorizontalPadding, 0.0);
    if (pos == 1) {
      caretOffset = caretOffset +
          new Offset(_lastChildSize.width + kHorizontalPadding, 0.0);
    }
    return caretOffset;
  }

  @override
  void paintSelection(PaintingContext context, Offset offset,
      TextSelection selection, Color selectionColor) {
    final localSelection = getLocalSelection(selection);
    assert(localSelection != null);
    if (!localSelection.isCollapsed) {
      final Paint paint = new Paint()
        ..color = selectionColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      final rect = new Rect.fromLTWH(
          0.0, 0.0, _lastChildSize.width, _lastChildSize.height);
      context.canvas.drawRect(rect.shift(offset + _childOffset), paint);
    }
  }

  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset + _childOffset);
  }

  static const double kHorizontalPadding = 1.0;

  Size _lastChildSize;

  Offset get _childOffset {
    final dx = (size.width - _lastChildSize.width) / 2 + kHorizontalPadding;
    final dy = (size.height - _lastChildSize.height - kPaddingBottom) / 2;
    return new Offset(dx, dy);
  }

  Rect get _childRect {
    return new Rect.fromLTWH(_childOffset.dx, _childOffset.dy,
        _lastChildSize.width, _lastChildSize.height);
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);
    if (child != null) {
      // Make constraints use 16:9 aspect ratio.
      final width = constraints.maxWidth - kHorizontalPadding * 2;
      final childConstraints = constraints.copyWith(
        minWidth: 0.0,
        maxWidth: width,
        minHeight: 0.0,
        maxHeight: (width * 9 / 16).floorToDouble(),
      );
      child.layout(childConstraints, parentUsesSize: true);
      _lastChildSize = child.size;
      size = new Size(
          constraints.maxWidth, _lastChildSize.height + kPaddingBottom);
    } else {
      performResize();
    }
  }
}

/// Goods 编辑页面
class GoodsEditer extends StatefulWidget {
  final ZefyrGoodsModel goodsModel;
  final OnSelectGoods onSelectGoods;

  GoodsEditer({Key key, this.goodsModel, @required this.onSelectGoods}) : super(key: key);

  @override
  _GoodsEditerState createState() => new _GoodsEditerState();
}

class _GoodsEditerState extends State<GoodsEditer> {
  ZefyrGoodsModel _goodsModel;
  TextEditingController editingController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      _goodsModel = widget.goodsModel;
      editingController = TextEditingController(text: _goodsModel?.content);
      editingController.addListener((){
        _goodsModel.content = editingController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double imgSize = size.width * 0.341333333333;
    return new Scaffold(
      appBar: new AppBar(
        backgroundColor: Color(0xffF6072F),
        title: new Text(
          '选择商品',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: Colors.white,
            ),
            onPressed: () {
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      height: 270.0,
                      padding: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: 26.0,
                            alignment: Alignment.center,
                            color: Colors.white,
                            margin: EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              width: 80.0,
                              height: 3.0,
                              decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(3.0)),
                                  color: Colors.grey),
                            ),
                          ),
                          Text(
                            "使用须知",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Container(height: 10.0),
                          Text("1、淘宝天猫直接粘贴复制的淘口令即可"),
                          Text("2、拼多多、感恩购商品输入商品链接"),
                          Text("2、未开启淘宝联盟推广与多多进宝的商品无法获得佣金提成"),
                          Container(height: 12.0),
                          Text("如何获得拼多多商品链接？", style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),),
                          Container(height: 10.0),
                          Text("1、将拼多多分享到微信，并在微信上打开"),
                          Text("2、进入微信网页后通过 【菜单 -> 复制链接】获取"),
                        ],
                      ),
                    );
                  });
            },
          ),
          FlatButton.icon(
            icon: Icon(
              Icons.check,
              color: _goodsModel == null ? Colors.grey[200] : Colors.white,
            ),
            label: Text(
              "确定",
              style: TextStyle(color: _goodsModel == null ? Colors.grey[200] : Colors.white),
            ),
            onPressed: _goodsModel == null ? null : () {
              if (widget.onSelectGoods != null) {
                Navigator.pop(context);
                widget.onSelectGoods(_goodsModel);
              }
            },
          )
        ],
        bottom: _SearchBar(
          onCancel: () {},
          onSearch: (keyword) async {
            try {
              final apiGoodsService = ApiGoodsService(keyword);
              if (apiGoodsService.verify() == false) {
                showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Container(
                        color: Colors.red,
                        height: 80.0,
                        alignment: Alignment.center,
                        child: Text(
                          "不支持的商品平台，只支持淘宝、天猫、拼多多",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }).timeout(Duration(seconds: 2));
              } else {
                final goods = await apiGoodsService.getData();
                setState(() {
                  _goodsModel = goods;
                });
              }
            } catch (e) {
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Container(
                      color: Colors.red,
                      height: 80.0,
                      alignment: Alignment.center,
                      child: Text(
                        e.toString(),
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  });
            }
            return Future.value(true);
          },
        ),
      ),
      body: _goodsModel != null ? editGoods() : loadWidget(),
    );
  }

  Widget editGoods() {
    Size size = MediaQuery.of(context).size;
    double imgSize = size.width * 0.341333333333;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          color: Colors.white,
          height: imgSize + 24.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                width: imgSize,
                height: imgSize,
                color: Colors.grey[200],
                margin: EdgeInsets.all(12.0),
                child: Image.network("https:" + _goodsModel.thumbs[0], width: imgSize, height: imgSize),
              ),
              Container(
                width: (size.width - imgSize - 24.0),
                padding:
                EdgeInsets.only(right: 12.0, top: 12.0, bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(_goodsModel.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),),
                          Container(height: 6.0),
                          Text(_goodsModel.subtitle == null ? "" : _goodsModel.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[600]),),
                        ],
                      ),
                    ),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            color: Colors.grey[200],
                            child: Text(" 券、奖励金实时查询 ", style: TextStyle(fontSize: 10),),
                          ),
                          Container(height: 4.0),
                          Text("¥" + _goodsModel.price, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[600]),),
                          Container(height: 4.0),
                          Text("销量: ${_goodsModel.volume}件", style: TextStyle(fontSize: 12, color: Colors.grey),)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(12.0),
          color: Colors.white,
          child: TextField(
            maxLines: 5,
            controller: editingController,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(0.0),
              border: InputBorder.none,
              hintText: "请用简短的文字阐述你的推荐理由",
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(12.0),
          child: Text("认真编辑才能获得更多的官方推荐", style: TextStyle(fontSize: 12),),
        ),
      ],
    );
  }

  Widget loadWidget() {
    Size size = MediaQuery.of(context).size;
    double imgSize = size.width * 0.341333333333;
    return Column(
      children: <Widget>[
        Container(
          color: Colors.white,
          height: imgSize + 24.0,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                width: imgSize,
                height: imgSize,
                color: Colors.grey[200],
                margin: EdgeInsets.all(12.0),
              ),
              Container(
                padding:
                EdgeInsets.only(right: 12.0, top: 12.0, bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: size.width - imgSize - 36.0,
                            height: 18.0,
                            color: Colors.grey[200],
                          ),
                          Container(height: 6.0),
                          Container(
                            width: (size.width - imgSize - 36.0) * 0.6,
                            height: 18.0,
                            color: Colors.grey[200],
                          )
                        ],
                      ),
                    ),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: (size.width - imgSize - 36.0) * 0.5,
                            height: 18.0,
                            color: Colors.grey[200],
                          ),
                          Container(height: 4.0),
                          Container(
                            width: (size.width - imgSize - 36.0) * 0.3,
                            height: 18.0,
                            color: Colors.grey[200],
                          ),
                          Container(height: 4.0),
                          Container(
                            width: (size.width - imgSize - 36.0) * 0.7,
                            height: 18.0,
                            color: Colors.grey[200],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: (size.width - 24.0),
                height: 18.0,
                color: Colors.grey[200],
              ),
              Container(height: 4.0),
              Container(
                width: (size.width - 24.0) * 0.7,
                height: 18.0,
                color: Colors.grey[200],
              ),
              Container(height: 4.0),
              Container(
                width: (size.width - 24.0) * 0.6,
                height: 18.0,
                color: Colors.grey[200],
              ),
              Container(height: 12.0),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}

typedef Future<bool> OnSearchCallback(String keyword);

class _SearchBar extends StatefulWidget implements PreferredSizeWidget {
  final OnSearchCallback onSearch;
  final VoidCallback onCancel;

  const _SearchBar({Key key, this.onSearch, this.onCancel}) : super(key: key);

  _SearchBarState createState() => _SearchBarState();

  // TODO: implement preferredSize
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _SearchBarState extends State<_SearchBar> {
  FocusNode _focusNode = FocusNode();
  TextEditingController _queryTextController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _queryTextController.addListener(onInput);
  }

  void onInput() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      alignment: Alignment.center,
      padding: EdgeInsets.only(
        left: 12.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Container(
              height: 38.0,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.0)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Center(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(minWidth: 38.0, minHeight: 38.0),
                      child: IconTheme.merge(
                        data: IconThemeData(
                          color: Colors.black54,
                          size: 24.0,
                        ),
                        child: Icon(Icons.search),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _queryTextController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (String _) {},
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(0.0),
                        border: InputBorder.none,
                        hintText: "商品链接或者淘口令",
                      ),
                      cursorColor: Colors.red,
                    ),
                  ),
                  _queryTextController.text == ""
                      ? Container()
                      : InkWell(
                          child: Center(
                            widthFactor: 1.0,
                            heightFactor: 1.0,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                  minWidth: 38.0, minHeight: 38.0),
                              child: IconTheme.merge(
                                data: IconThemeData(
                                  color: Colors.grey,
                                  size: 24.0,
                                ),
                                child: Icon(Icons.close),
                              ),
                            ),
                          ),
                          onTap: () {
                            _queryTextController.clear();
                            widget.onCancel();
                          },
                        )
                ],
              ),
            ),
          ),
          InkWell(
            onTap: _queryTextController.text.isEmpty == false && loading == false
                ? () {
                    setState(() {
                      loading = true;
                    });
                    widget.onSearch(_queryTextController.text).then((t){
                      setState(() {
                        loading = false;
                      });
                    });
                  }
                : null,
            child: Container(
              width: 88.0,
              height: 38.0,
              alignment: Alignment.center,
              child: loading == true
                  ? CupertinoActivityIndicator(
                      animating: true,
                    )
                  : Text(
                      "搜索",
                      style: TextStyle(
                        color: _queryTextController.text.isEmpty == false
                            ? Colors.white
                            : Colors.grey[200],
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _queryTextController.removeListener(onInput);
  }
}

enum GoodsTypes { taobao, tmall, pinduoduo }

/// 获取淘宝、天猫、拼多多商品详情
class ApiGoodsService {
  final String url;

  ApiGoodsService(this.url);

  GoodsTypes _type;
  GoodsTypes get type => _type;

  // 验证是否正确
  bool verify() {
    if (new RegExp(r"￥.*?￥").hasMatch(url)) {
      _type = GoodsTypes.taobao;
      return true;
    } else if (url.indexOf("mobile.yangkeduo.com") > -1) {
      _type = GoodsTypes.pinduoduo;
      return Uri.parse(url).queryParameters.containsKey("goods_id");
    }
    return false;
  }

  Future<ZefyrGoodsModel> getData() async {
    if (this._type == GoodsTypes.taobao || this._type == GoodsTypes.tmall) {
      return _taobao();
    } else if (this._type == GoodsTypes.pinduoduo) {
      return _pinduoduo();
    }
    return Future.error("只支持淘宝、天猫、拼多多、感恩购平台商品");
  }

  Future<int> getKouling() async {
    HttpClient httpClient = new HttpClient();
    final request = await httpClient.getUrl(Uri(
        scheme: "http",
        host: "192.168.1.2",
        port: 5928,
        path: "/api/2.0/api.taobao.kouling",
        queryParameters: {"data": url}));
    var response = await request.close();
    var responseBody = await response.transform(utf8.decoder).join();
    final Map<String, dynamic> jsonData = json.decode(responseBody);
    if (jsonData["errcode"] != 200) {
      return Future.error(jsonData['msg']);
    }
//    print(jsonData['data']);
    if ((jsonData['data'] as Map<String, dynamic>).containsKey("native_url") == false) {
      return Future.error("无效的淘口令");
    }
    if ((jsonData['data']['native_url'] as String).indexOf("m.taobao.com%2Fi") >
        -1) {
      final jsonRegExp = new RegExp(r'm\.taobao\.com%2Fi(\d*?)\.htm')
          .firstMatch(jsonData['data']['native_url']);
      if (jsonRegExp.groupCount > 0) {
        return int.parse(jsonRegExp.group(1));
      }
    }
    return Future.error("淘宝/天猫数据同步异常");
  }

  /// 获取淘宝商品数据
  /// 淘宝接口 sign 计算方法 在cookie中获取 _m_h5_tk 传入的接口参数 根据这个顺序组合后md5加密
  /// n = 接口需要的所有参数，a = 时间戳， s = appKey 公共的是12574478；
  /// sign = md5(o.token + "&" + a + "&" + s + "&" + n.data)
  /// n.jsv = 2.4.8;
  /// n.appKey = s;
  /// n.t = a;
  /// n.sign = u;
  /// 将 n 发送到 https://h5api.m.taobao.com/h5/mtop.taobao.detail.getdetail/6.0/
  Future<ZefyrGoodsModel> _taobao() async {
    try {
      final kouling = await getKouling();
      final t = DateTime.now().millisecondsSinceEpoch;
      final appkey = 12574478;
      final token = "";
      final Map<String, String> param = {
        "api": "mtop.taobao.detail.getdetail",
        "v": "6.0",
        "ecode": "0",
        "dataType": "jsonp",
        "appKey": "12574478",
        "data": "${json.encode({"itemNumId": kouling.toString()})}",
        "t": "$t",
        "appkey": "$appkey",
        "jsv": "2.4.16",
        "ttid": "2017@taobao_h5_6.6.0",
      };
      param["sign"] = generateMd5("$token&$t&$appkey&${param['data']}");
      HttpClient httpClient = new HttpClient();
      var request = await httpClient.getUrl(Uri.https("h5api.m.taobao.com",
          "/h5/mtop.taobao.detail.getdetail/6.0/", param));

      var response = await request.close();
      var responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> jsonData = json.decode(responseBody);
      if (jsonData.containsKey('ret') &&
          (jsonData['ret'][0] as String).indexOf("SUCCESS") > -1) {
        final _pdata = jsonData['data'];
        final Map<String, dynamic> _apiStack =
            json.decode(jsonData['data']['apiStack'][0]['value']);
        final zefyrGoodsModel = new ZefyrGoodsModel(
            id: int.parse(_pdata['item']['itemId']),
            title: _pdata['item']['title'],
            subtitle: _pdata['item']['subtitle'],
            thumbs: _pdata['item']['images'].cast<String>(),
            platform: _pdata['seller']['shopType'] == "C" ? 'taobao' : 'tmall',
            price: _apiStack['price']['price']['priceText'],
            volume: int.parse(_apiStack['item']['sellCount']),
            content: '');
        return zefyrGoodsModel;
      } else {
        return Future.error("由于淘宝平台升级，数据同步迟缓请等待官方升级");
      }
    } catch (e) {
      return Future.error("淘宝/天猫数据同步异常");
    }
  }

  Future<ZefyrGoodsModel> _pinduoduo() async {
    try {
      HttpClient httpClient = new HttpClient();
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();
      var responseBody = await response.transform(utf8.decoder).join();
      final jsonRegExp = new RegExp(
              r'<script nonce="\d*">\s*window.rawData=([\s\S]*?);\s*</script>')
          .firstMatch(responseBody);
      if (jsonRegExp != null) {
        final Map<String, dynamic> jsonStr = json.decode(jsonRegExp.group(1));
        final _pgoods = jsonStr['initDataObj']['goods'];
        final zefyrGoodsModel = new ZefyrGoodsModel(
            id: _pgoods['goodsID'],
            title: _pgoods['goodsName'],
            thumbs: _pgoods['topGallery'].cast<String>(),
            platform: 'pinduoduo',
            price: _pgoods['minGroupPrice'].toString(),
            volume: _pgoods['sales'],
            content: '');
        return zefyrGoodsModel;
      } else {
        return Future.error("由于拼多多平台升级，数据同步迟缓请等待官方升级");
      }
    } catch (e) {
      return Future.error("拼多多数据同步异常");
    }
  }
}
