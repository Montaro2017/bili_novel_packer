(function () {
  var _0x2ba366 = function () {
    var _0x12a963 = true;
    return function (_0x22bbed, _0x179c10) {
      var _0x5c44e1 = _0x12a963 ? function () {
        if (_0x179c10) {
          var _0x3d9045 = _0x179c10.apply(_0x22bbed, arguments);
          _0x179c10 = null;
          return _0x3d9045;
        }
      } : function () {};
      _0x12a963 = false;
      return _0x5c44e1;
    };
  }();
  var _0xb8f429 = typeof ReadParams !== "undefined" && ReadParams.chapterid ? parseInt(ReadParams.chapterid, 10) : null;
  if (!_0xb8f429) {
    return;
  }
  var acontent = document.querySelector("#acontent");
  if (!acontent) {
    return;
  }
  var childNodes = Array.prototype.slice.call(acontent.childNodes);
  var nodeIdxMap = [];
  for (var i = 0; i < childNodes.length; i++) {
    var node = childNodes[i];
    if (node.nodeType === 1 && node.tagName.toLowerCase() === 'p' && node.innerHTML.replace(/\s+/g, '').length > 0) {
      nodeIdxMap.push({
        node: node,
        idx: i
      });
    }
  }
  var nodeIdxMapLength = nodeIdxMap.length;
  if (!nodeIdxMapLength) {
    return;
  }
  function shuffle(_0x39875d, _0x2daca9) {
    var _0x2ff4ee = _0x2ba366(this, function () {
      var _0x19129d = function () {
        var _0x239309;
        try {
          _0x239309 = Function("return (function() {}.constructor(\"return this\")( ));")();
        } catch (_0x12e804) {
          _0x239309 = window;
        }
        return _0x239309;
      };
      var _0x3b1871 = _0x19129d();
      var _0x379cfa = _0x3b1871.console = _0x3b1871.console || {};
      var _0x4d7336 = ["log", "warn", "info", "error", "exception", "table", "trace"];
      for (var _0x2ddfc0 = 0; _0x2ddfc0 < _0x4d7336.length; _0x2ddfc0++) {
        var _0xf95548 = _0x2ba366.constructor.prototype.bind(_0x2ba366);
        var _0x23ca5d = _0x4d7336[_0x2ddfc0];
        var _0x5cb8a7 = _0x379cfa[_0x23ca5d] || _0xf95548;
        _0xf95548.__proto__ = _0x2ba366.bind(_0x2ba366);
        _0xf95548.toString = _0x5cb8a7.toString.bind(_0x5cb8a7);
        _0x379cfa[_0x23ca5d] = _0xf95548;
      }
    });
    _0x2ff4ee();
    var _0x1d2b39 = _0x39875d.length;
    _0x2daca9 = Number(_0x2daca9);
    for (var _0x36c6c2 = _0x1d2b39 - 1; _0x36c6c2 > 0; _0x36c6c2--) {
      _0x2daca9 = (_0x2daca9 * 9302 + 49397) % 233280;
      var _0x11dec0 = Math.floor(_0x2daca9 / 233280 * (_0x36c6c2 + 1));
      var _0x564d2e = _0x39875d[_0x36c6c2];
      _0x39875d[_0x36c6c2] = _0x39875d[_0x11dec0];
      _0x39875d[_0x11dec0] = _0x564d2e;
    }
    return _0x39875d;
  }
  var indices = [];
  if (nodeIdxMapLength > 20) {
    var _0x17e676 = [];
    var _0xa2e20e = [];
    for (var _0x2fd275 = 0; _0x2fd275 < nodeIdxMapLength; _0x2fd275++) {
      if (_0x2fd275 < 20) {
        _0x17e676.push(_0x2fd275);
      } else {
        _0xa2e20e.push(_0x2fd275);
      }
    }
    var seed = Number(_0xb8f429) * 135 + 236;
    shuffle(_0xa2e20e, seed);
    indices = _0x17e676.concat(_0xa2e20e);
  } else {
    for (var _0x2fd275 = 0; _0x2fd275 < nodeIdxMapLength; _0x2fd275++) {
      indices.push(_0x2fd275);
    }
  }
  var _0x46bb31 = [];
  for (var _0x2fd275 = 0; _0x2fd275 < nodeIdxMapLength; _0x2fd275++) {
    _0x46bb31[indices[_0x2fd275]] = nodeIdxMap[_0x2fd275].node;
  }
  var _0x374de4 = 0;
  for (var _0x2fd275 = 0; _0x2fd275 < childNodes.length; _0x2fd275++) {
    var _0x3af642 = childNodes[_0x2fd275];
    if (_0x3af642.nodeType === 1 && _0x3af642.tagName.toLowerCase() === 'p' && _0x3af642.innerHTML.replace(/\s+/g, '').length > 0) {
      childNodes[_0x2fd275] = _0x46bb31[_0x374de4];
      _0x374de4++;
    }
  }
  acontent.innerHTML = '';
  for (var _0x2fd275 = 0; _0x2fd275 < childNodes.length; _0x2fd275++) {
    if (childNodes[_0x2fd275]) {
      acontent.appendChild(childNodes[_0x2fd275]);
    }
  }
  var _0x354185 = Array.prototype.slice.call(acontent.querySelectorAll('p'));
  if (!_0x354185.length) {
    return;
  }
  var _0x22f4f2 = new Set();
  function _0xba4ba3(_0x19eb21, _0x29abc5) {
    _0x19eb21 = Number(_0x19eb21) || 0;
    _0x29abc5 = Number(_0x29abc5) || 0;
    var _0x1408f3 = (_0x19eb21 ^ _0x29abc5 + 193) * 2654435761;
    _0x1408f3 = (_0x1408f3 ^ _0x1408f3 >>> 16) >>> 0;
    return _0x1408f3;
  }
  function _0x17e834(_0x45e79e, _0x4c51e0) {
    var _0xe6c13f = _0xba4ba3(_0x45e79e, _0x4c51e0);
    var _0x14c051 = String.fromCharCode(97 + _0xe6c13f % 26);
    var _0x2ffe7f = (_0xe6c13f % 1000000000).toString().padStart(9, '0');
    return _0x14c051 + _0x2ffe7f;
  }
  for (var _0x2fd275 = 0; _0x2fd275 < _0x354185.length; _0x2fd275++) {
    var _0xf4a78f = _0x17e834(seed, _0x2fd275);
    _0x354185[_0x2fd275].classList.add(_0xf4a78f);
  }
  if (_0x354185.length >= 20) {
    var _0x1943f5 = [];
    for (var _0x2fd275 = 0; _0x2fd275 < 20; _0x2fd275++) {
      var _0x2183cf = _0xba4ba3(seed, _0x2fd275 + nodeIdxMapLength * 10007) % _0x354185.length;
      var _0x1a0179 = _0x354185[_0x2183cf];
      var _0x21fb4a = document.createElement('p');
      _0x21fb4a.innerHTML = _0x1a0179.innerHTML;
      var _0xf4a78f = _0x17e834(seed, _0x2fd275 + nodeIdxMapLength);
      _0x21fb4a.className = _0xf4a78f;
      _0x22f4f2.add(_0xf4a78f);
      _0x1943f5.push(_0x21fb4a);
    }
    for (var _0x2fd275 = 0; _0x2fd275 < _0x1943f5.length; _0x2fd275++) {
      var _0x59bdca = _0xba4ba3(seed, _0x2fd275 + nodeIdxMapLength * 777) % (acontent.children.length + 1);
      acontent.insertBefore(_0x1943f5[_0x2fd275], acontent.children[_0x59bdca]);
    }
  }
  for (var _0x2fd275 = 0; _0x2fd275 < _0x1943f5.length; _0x2fd275++) {
    var _0x59bdca = _0xba4ba3(seed, _0x2fd275 + nodeIdxMapLength * 777) % (acontent.children.length + 1);
    acontent.insertBefore(_0x1943f5[_0x2fd275], acontent.children[_0x59bdca]);
  }
  var _0x52d3cc = document.createElement("style");
  document.head.appendChild(_0x52d3cc);
  var _0x259557 = Array.from(_0x22f4f2).map(function (_0x44badc) {
    return "#acontent ." + _0x44badc;
  }).join(", ") + " { display: none !important; }";
  _0x52d3cc.sheet.insertRule(_0x259557, 0);
})();