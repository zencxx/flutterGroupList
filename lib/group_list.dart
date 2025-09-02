import 'package:flutter/material.dart';

enum ListViewGroupHelperIndexPathPosition {
  header,
  content,
  footer,
  tableHeader,
  tableFooter,
}

class ListViewGroupHelperIndexPath {
  ListViewGroupHelperIndexPath({
    this.position = ListViewGroupHelperIndexPathPosition.tableHeader,
    this.section = -1,
    this.row = -1,
  }) : assert(
          (position == ListViewGroupHelperIndexPathPosition.content &&
                  section >= 0 &&
                  row >= 0) ||
              (position == ListViewGroupHelperIndexPathPosition.header &&
                  section >= 0) ||
              (position == ListViewGroupHelperIndexPathPosition.footer &&
                  section >= 0) ||
              position == ListViewGroupHelperIndexPathPosition.tableHeader ||
              position == ListViewGroupHelperIndexPathPosition.tableFooter,
        );
  ListViewGroupHelperIndexPathPosition position;
  int section;
  int row;

  @override
  String toString() {
    return "position: $position section: $section row: $row";
  }
}

/// header + footer + item 必须 > 0
/// 使用 ListView.builder
class ListViewGroupHelper {
  int _sectionCount = 0;
  final List<int> _itemCountData = [];
  final List<bool> _headerData = [];
  final List<bool> _footerData = [];
  final List<int> _sectionPoint = []; //section的终点index 不含
  bool _tableHeader = false;
  bool _tableFooter = false;

  void dataSourceProvide({
    required int sectionCount,
    required bool Function(int section) containHeaderInSection,
    required bool Function(int section) containFooterInSection,
    required int Function(int section) itemCountInSection,
    bool containTableHeader = false,
    bool containTableFooter = false,
  }) {
    _sectionCount = sectionCount;
    _sectionPoint.clear();
    _itemCountData.clear();
    _headerData.clear();
    _footerData.clear();
    _tableHeader = containTableHeader;
    _tableFooter = containTableFooter;

    int v = 0;
    for (var i = 0; i < _sectionCount; i++) {
      bool containHeader = containHeaderInSection(i);
      _headerData.add(containHeader);
      bool containFooter = containFooterInSection(i);
      _footerData.add(containFooter);
      int itemCount = itemCountInSection(i);
      _itemCountData.add(itemCount);
      v += itemCount;
      if (containHeader && containFooter) {
        v += 2;
      } else if (containFooter || containHeader) {
        v += 1;
      }
      _sectionPoint.add(v);
    }
  }

  ///分组后的数据返回
  Widget widgetForIndex({
    required int index,
    Widget Function(int section)? headerInSection,
    Widget Function(int section)? footerInSection,
    Widget Function()? tableHeader,
    Widget Function()? tableFooter,
    required Widget Function(int section, int row) itemInIndexPath,
  }) {
    if (index == 0) {
      if (_tableHeader) {
        assert(tableHeader != null);
        return tableHeader!.call();
      }
    }
    if (index == totalRowCount() - 1) {
      if (_tableFooter) {
        assert(tableFooter != null);
        return tableFooter!.call();
      }
    }
    if (_tableHeader) {
      index--;
    }

    var section = 0, row = 0;
    for (var i = 0; i < _sectionPoint.length; i++) {
      int point = _sectionPoint[i];
      int previousPoint = i > 0 ? _sectionPoint[i - 1] : 0;
      bool containHeader = _headerData[i];
      bool containFooter = _footerData[i];
      int itemCount = _itemCountData[i];

      if (index < point && index >= previousPoint) {
        section = i;
        row = index - previousPoint;

        // printSome("section = $section row = $row");

        if (row == 0) {
          if (containHeader) {
            return headerInSection!(section);
          } else if (itemCount > 0) {
            return itemInIndexPath(section, row);
          } else {
            return footerInSection!(section);
          }
        } else {
          if (containHeader && containFooter) {
            if (row == itemCount + 2 - 1) {
              return footerInSection!(section);
            }
            return itemInIndexPath(section, row - 1);
          } else if (containHeader) {
            return itemInIndexPath(section, row - 1);
          } else if (containFooter) {
            if (row == itemCount + 1 - 1) {
              return footerInSection!(section);
            }
            return itemInIndexPath(section, row);
          } else {
            return itemInIndexPath(section, row);
          }
        }
      }
    }
    return Container();
  }

  ///根据indexPath获取index值
  int indexForIndexPath({required ListViewGroupHelperIndexPath indexPath}) {
    assert(indexPath.section < _itemCountData.length);
    if (indexPath.position ==
        ListViewGroupHelperIndexPathPosition.tableHeader) {
      return 0;
    }
    if (indexPath.position ==
        ListViewGroupHelperIndexPathPosition.tableFooter) {
      return totalRowCount() - 1;
    }
    int index = 0;
    for (var i = 0; i <= indexPath.section; i++) {
      bool containHeader = _headerData[i];
      bool containFooter = _footerData[i];
      int itemCount = _itemCountData[i];

      if (i == indexPath.section) {
        if (indexPath.position == ListViewGroupHelperIndexPathPosition.header) {
          index++;
        } else if (indexPath.position ==
            ListViewGroupHelperIndexPathPosition.content) {
          if (containHeader) {
            index++;
          }
          index += ((indexPath.row) + 1);
        } else if (indexPath.position ==
            ListViewGroupHelperIndexPathPosition.footer) {
          if (containHeader) {
            index++;
          }
          index++;
          index += itemCount;
        }
        break;
      }
      if (containHeader) {
        index++;
      }
      if (containFooter) {
        index++;
      }
      index += itemCount;
    }

    index += (_tableHeader ? 1 : 0);

    return index - 1;
  }

  ///计算一个原始index的新位置
  ListViewGroupHelperIndexPath? indexPathForIndex({
    required int index,
  }) {
    if (index == 0 && _tableHeader) {
      return ListViewGroupHelperIndexPath(
          position: ListViewGroupHelperIndexPathPosition.tableHeader);
    }
    if (index == totalRowCount() - 1 && _tableFooter) {
      return ListViewGroupHelperIndexPath(
          position: ListViewGroupHelperIndexPathPosition.tableFooter);
    }

    if (_tableHeader) {
      index--;
    }

    var section = 0, row = 0;
    for (var i = 0; i < _sectionPoint.length; i++) {
      int point = _sectionPoint[i];
      int previousPoint = i > 0 ? _sectionPoint[i - 1] : 0;
      bool containHeader = _headerData[i];
      bool containFooter = _footerData[i];
      int itemCount = _itemCountData[i];

      if (index < point && index >= previousPoint) {
        section = i;
        row = index - previousPoint;
        var indexPath = ListViewGroupHelperIndexPath()..section = section;

        if (row == 0) {
          if (containHeader) {
            return indexPath
              ..position = ListViewGroupHelperIndexPathPosition.header;
          } else if (itemCount > 0) {
            return indexPath
              ..position = ListViewGroupHelperIndexPathPosition.content
              ..row = row;
          } else {
            return indexPath
              ..position = ListViewGroupHelperIndexPathPosition.footer;
          }
        } else {
          if (containHeader && containFooter) {
            if (row == itemCount + 2 - 1) {
              return indexPath
                ..position = ListViewGroupHelperIndexPathPosition.footer;
            }
            return indexPath
              ..position = ListViewGroupHelperIndexPathPosition.content
              ..row = row - 1;
          } else if (containHeader) {
            return indexPath
              ..position = ListViewGroupHelperIndexPathPosition.content
              ..row = row - 1;
          } else if (containFooter) {
            if (row == itemCount + 1 - 1) {
              return indexPath
                ..position = ListViewGroupHelperIndexPathPosition.footer;
            }
            return indexPath
              ..position = ListViewGroupHelperIndexPathPosition.content
              ..row = row;
          } else {
            return indexPath
              ..position = ListViewGroupHelperIndexPathPosition.content
              ..row = row;
          }
        }
      }
    }
    return null;
  }

  ///原始widget的总行数
  int totalRowCount() {
    int count = 0 + (_tableHeader ? 1 : 0) + (_tableFooter ? 1 : 0);
    if (_sectionPoint.isEmpty) {
      return count;
    }
    return _sectionPoint.last + count;
  }

  ///组数
  int sectionCount() {
    return _sectionCount;
  }

  ///组包含的行数
  int rowCountInSection(int section) {
    return _itemCountData[section];
  }

  ///最后组的index
  int lastSectionIndex() {
    return _sectionCount - 1;
  }

  ///组的最后一行的index
  int lastRowIndexInSection(int section) {
    return _itemCountData[section] - 1;
  }
}
