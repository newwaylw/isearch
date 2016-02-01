# Telecom company name coding and input tool
# iSearch – 机构名称快速检索系统

## Methodology

### 1. The requirement

For any given pinyin letter sequence, the tool produces ranked matches from the specific company list. 

The simplest case is that each letter within the input sequence represents the Chinese character within the company name. For example, 

“SZHWJSYXGS” represents “深圳华为技术有限公司”. However, users usually 

follow the other cases below. 

* 用户将公司名称中的某个字说错，例如“深圳宏鼎食品加工有限公司”（实为“深圳宏德食品加工有限公司”）。用户记忆能力有限，这种情况比较多。

* 用户用了不完整的公司名称，或者用公司简称，例如“青苹果公司”（实为“深圳市青苹果广告有限公司”）；

* 用户使用了公司名称中个别词汇的同义词，例如“深圳洪德食品厂”（实为“深圳宏德食品加工有限公司”）；

* 用户将公司名称中个别词汇的顺序弄颠倒，例如“深圳兴法食品加工有限公司”（实为“兴法食品加工深圳有限公司”）；

* Other cases might exist and the list keeps expanding.

The input tool should be able to handle all the cases to satisfy the 
requirement, that is, for any given pinyin letter sequence, the tool produces ranked matches from the specific company list.

### 2. The models

This tool makes use of statistical domain heuristics and language models in its predicting. The rank is assigned according the overall probability that every candidate matches the input letters. 

1) Domain heuristics:

Domain heuristics refer to the widely accepted rules that the company 
names follows to spell themselves. The following assumptions are interesting.

* 根据中国工商部门有关公司注册的规定，所有的公司名称全称都包含地
点(R)、机构名称表征词(U)、机构类型(T)和名称后缀(S)。例如“深圳华
为技术有限公司”中，R=深圳，U=华为，T=技术，S=有限公司。

* 公司名称的最强省略是公司简称。例如，“华为”。简称是搜索中优先
级最高的一类名称。例如对输入的“SZ”，应优先提供“深证”，而
不是“深圳”。这是因为，前者是一个U，而后者是R，U的优先级高于R。

* 原则上公司名称中的不同部分的输入可以颠倒顺序，但各部分内部字的顺序是不可颠倒的，例如“深圳”不可能是“圳深”。同时，各部分之间的顺序实际上存在某种确定性，即T总是出现在U之后，S总是出现在T之后 “有限公司”。例如“UUTTSSSS”（华为技术有限公司）。
只有R的出现可灵活。

* 公司名称编码输入错误的主要来源是公司名称表征词(U)，因此模糊匹
配主要在U部分实施。这部分错误可采取基于公司名录语言模型进行预
测。由于采取拼音字母匹配，本身就能模糊一批错误，例如“华为”和
“华闻”。非同一生母的错误，要借助R和T的限定进行预测和校准。

* 公司类型称谓的变化可预测。可采取列表方式提前枚举现有类型。例如
“技术”、“食品”等。

* 名称后缀的变化可预测。可采取列表方式提前枚举现有类型。例如“有
限公司”、“学校”、“店”、“工作室”、“行”、“管理处”、“
酒店”、“超市”、“商店”等。

To reflect the above assumptions, rules are designed. 
For the parts that are easily recognized, the tool handles them in the first step with very high confidence. Then these parts will in turn provide heuristics for the language models to handle the most difficult part. 

2) Language models

The language models measure following facts.

* How do the parts determine the company names by probabilistically 

combining with each other?

* How do characters combine each other to form the company names? 


-------------------------------------------------------


目录文件

    /cache  缓存文件夹
    /class 库文件，主要是模板库
    /css 网页样式表文件所在文件夹
    /data search.pl所在的文件夹
    /data/search.pl  搜索核心算法的perl文件
    /html 网页模板
    /images 图片
    /pgadmin 数据库管理程序
    /temp 临时文件夹
    config.inc.php 配置文件
    index.php 首页
    search.php 查询
    index.php  见文件内部注释
    search.php 见文件内部注释