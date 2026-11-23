import 'package:flutter_test/flutter_test.dart';
import 'package:movies/data/api/wenku8_api_service.dart';
import 'package:movies/data/parsing/wenku8_xml_parser.dart';

void main() {
  group('Wenku8ApiService.magicAppver', () {
    test('黄金值（服务端实证，分钟桶 29919405）', () {
      final appver = Wenku8ApiService.magicAppver(
        at: DateTime.fromMillisecondsSinceEpoch(29919405 * 60000),
      );
      expect(appver, '1.30-digital-bento-14533206');
    });

    test('同一分钟内稳定、跨分钟变化', () {
      final base = DateTime.fromMillisecondsSinceEpoch(29919405 * 60000);
      expect(
        Wenku8ApiService.magicAppver(at: base),
        Wenku8ApiService.magicAppver(
          at: base.add(const Duration(seconds: 59)),
        ),
      );
      expect(
        Wenku8ApiService.magicAppver(at: base),
        isNot(Wenku8ApiService.magicAppver(
          at: base.add(const Duration(seconds: 61)),
        )),
      );
    });
  });

  group('parseWenku8NovelItems', () {
    test('解析搜索/列表 item（data 字段 + CDATA 标题）', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<result>
<item aid='1587'>
<data name='Title'><![CDATA[无职转生]]></data>
<data name='TotalHitsCount' value='2606813'/>
<data name="Author" value='理不尽な孙の手'/>
<data name='BookStatus' value='已完成'/>
<data name="Tags" value='穿越 魔法'/>
<data name='IntroPreview'><![CDATA[异世界转生……]]></data>
</item>
<item aid='4346'>
<data name='Title'><![CDATA[看不见的规则]]></data>
<data name="Author" value='佐藤いつ子'/>
</item>
<item aid='9999'/>
</result>
''';
      final items = parseWenku8NovelItems(xml);
      // 仅 aid 无标题的 item 被过滤
      expect(items, hasLength(2));
      expect(items[0].id, '1587');
      expect(items[0].title, '无职转生');
      expect(items[0].subtitle, '理不尽な孙の手');
      expect(items[0].cover, 'https://img.wenku8.com/image/1/1587/1587s.jpg');
      expect(items[1].id, '4346');
    });
  });

  group('parseWenku8BookMeta', () {
    test('解析元数据（value 属性与 CDATA 两种形态）', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<metadata>
<data name="Title" aid="1306"><![CDATA[向森之魔物献上花束]]></data>
<data name="Author" value="小木君人"/>
<data name="BookStatus" value="已完成"/>
<data name="LastUpdate" value="2012-11-02"/>
<data name='IntroPreview'><![CDATA[在剑与魔法的世界里……]]></data>
</metadata>
''';
      final meta = parseWenku8BookMeta(xml);
      expect(meta['title'], '向森之魔物献上花束');
      expect(meta['author'], '小木君人');
      expect(meta['intro'], '在剑与魔法的世界里……');
    });
  });

  group('parseWenku8Catalog', () {
    test('解析分卷目录（volume/CDATA 卷名 + chapter/CDATA 章名）', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<package>
<volume vid="41748"><![CDATA[第一卷 告白于苍刻之夜]]>
<chapter cid="41749"><![CDATA[序章]]></chapter>
<chapter cid="41759"><![CDATA[插图]]></chapter>
</volume>
<volume vid="45090"><![CDATA[第二卷 谎言、真相与赤红]]>
<chapter cid="45091"><![CDATA[序章]]></chapter>
</volume>
</package>
''';
      final chapters = parseWenku8Catalog(xml);
      expect(chapters, hasLength(3));
      expect(chapters[0].chapterId, '41749');
      expect(chapters[0].title, '序章');
      expect(chapters[0].volumeTitle, '第一卷 告白于苍刻之夜');
      expect(chapters[2].volumeTitle, '第二卷 谎言、真相与赤红');
    });
  });

  group('normalizeWenku8ChapterText', () {
    test('单换行分段 → \\n\\n 段落；保留插图标记行；丢空行', () {
      const raw = '\r\n 第一卷 插图 \r\n \r\n    台版 转自 天使动漫论坛 \r\n\r\n'
          '<!--image-->http://pic.wenku8.com/pictures/1/1305/41759/50471.jpg<!--image-->\r\n'
          '    正文段落。 \r\n';
      final text = normalizeWenku8ChapterText(raw);
      expect(
        text,
        '第一卷 插图\n\n台版 转自 天使动漫论坛\n\n'
        '<!--image-->http://pic.wenku8.com/pictures/1/1305/41759/50471.jpg<!--image-->\n\n'
        '正文段落。',
      );
    });

    test('一行多图连排 → 每图独立段落（阅读器一段一图）', () {
      const raw = '<!--image-->https://a/1.jpg<!--image-->       '
          '<!--image-->https://a/2.jpg<!--image-->';
      final text = normalizeWenku8ChapterText(raw);
      expect(text.split('\n\n'), [
        '<!--image-->https://a/1.jpg<!--image-->',
        '<!--image-->https://a/2.jpg<!--image-->',
      ]);
    });

    test('图文混排行 → 文本与图各自成段', () {
      const raw = '卷首语 <!--image-->https://a/1.jpg<!--image--> 尾声';
      final text = normalizeWenku8ChapterText(raw);
      expect(text.split('\n\n'), [
        '卷首语',
        '<!--image-->https://a/1.jpg<!--image-->',
        '尾声',
      ]);
    });

    test('字面 null 行被丢弃（接口缺章信号）', () {
      expect(normalizeWenku8ChapterText('null'), isEmpty);
    });
  });

  group('isWenku8TextUnavailable', () {
    test('版权下架与缺章判据', () {
      expect(isWenku8TextUnavailable('因版权问题，文库不再提供'), isTrue);
      expect(isWenku8TextUnavailable('null'), isTrue);
      expect(isWenku8TextUnavailable('正常正文'), isFalse);
    });
  });

  group('wenku8CoverUrl', () {
    test('封面 URL 模式（k = aid/1000）', () {
      expect(wenku8CoverUrl('1305'), 'https://img.wenku8.com/image/1/1305/1305s.jpg');
      expect(wenku8CoverUrl('3794'), 'https://img.wenku8.com/image/3/3794/3794s.jpg');
    });
  });
}
