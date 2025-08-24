(function () {
  var chapterId = typeof ReadParams !== "undefined" && ReadParams.chapterid ? parseInt(ReadParams.chapterid, 10) : null;
  if (!chapterId) {
    return;
  }
  var acontent = document.querySelector("#acontent");
  if (!acontent) {
    return;
  }
  var _0x275693 = Array.prototype.slice.call(acontent.childNodes);
  var _0x40eedc = [];
  for (var _0x258364 = 0; _0x258364 < _0x275693.length; _0x258364++) {
    var _0x47a63d = _0x275693[_0x258364];
    if (_0x47a63d.nodeType === 1 && _0x47a63d.tagName.toLowerCase() === 'p' && _0x47a63d.innerHTML.replace(/\s+/g, '').length > 0) {
      var _0x342ed4 = {
        node: _0x47a63d,
        idx: _0x258364
      };
      _0x40eedc.push(_0x342ed4);
    }
  }
  var _0x56eeb2 = _0x40eedc.length;
  if (!_0x56eeb2) {
    return;
  }

  function _0x2fa95d(_0x1673ee, _0x43e4cf) {
    var _0x505b15 = _0x1673ee.length;
    _0x43e4cf = Number(_0x43e4cf);
    for (var _0x20df3d = _0x505b15 - 1; _0x20df3d > 0; _0x20df3d--) {
      _0x43e4cf = (_0x43e4cf * 9302 + 49397) % 233280;
      var _0x2ac62d = Math.floor(_0x43e4cf / 233280 * (_0x20df3d + 1));
      var _0x6806a5 = _0x1673ee[_0x20df3d];
      _0x1673ee[_0x20df3d] = _0x1673ee[_0x2ac62d];
      _0x1673ee[_0x2ac62d] = _0x6806a5;
    }
    return _0x1673ee;
  }

  var _0x3b03cd = [];
  if (_0x56eeb2 > 20) {
    var _0x43004a = [];
    var _0x21d22b = [];
    for (var _0x258364 = 0; _0x258364 < _0x56eeb2; _0x258364++) {
      if (_0x258364 < 20) {
        _0x43004a.push(_0x258364);
      } else {
        _0x21d22b.push(_0x258364);
      }
    }
    var _0x33fbcf = Number(chapterId) * 135 + 234;
    _0x2fa95d(_0x21d22b, _0x33fbcf);
    _0x3b03cd = _0x43004a.concat(_0x21d22b);
  } else {
    for (var _0x258364 = 0; _0x258364 < _0x56eeb2; _0x258364++) {
      _0x3b03cd.push(_0x258364);
    }
  }
  var _0x50e093 = [];
  for (var _0x258364 = 0; _0x258364 < _0x56eeb2; _0x258364++) {
    _0x50e093[_0x3b03cd[_0x258364]] = _0x40eedc[_0x258364].node;
  }
  var _0x4d8ead = 0;
  for (var _0x258364 = 0; _0x258364 < _0x275693.length; _0x258364++) {
    var _0x47a63d = _0x275693[_0x258364];
    if (_0x47a63d.nodeType === 1 && _0x47a63d.tagName.toLowerCase() === 'p' && _0x47a63d.innerHTML.replace(/\s+/g, '').length > 0) {
      _0x275693[_0x258364] = _0x50e093[_0x4d8ead];
      _0x4d8ead++;
    }
  }
  acontent.innerHTML = '';
  for (var _0x258364 = 0; _0x258364 < _0x275693.length; _0x258364++) {
    if (_0x275693[_0x258364]) {
      acontent.appendChild(_0x275693[_0x258364]);
    }
  }
  var _0x1a718f = Array.prototype.slice.call(acontent.querySelectorAll('p'));
  if (!_0x1a718f.length) {
    return;
  }
  var _0x4527fe = new Set();

  function _0x4f54e5(_0x549242, _0xe1a09c) {
    _0x549242 = Number(_0x549242) || 0;
    _0xe1a09c = Number(_0xe1a09c) || 0;
    var _0x2d0675 = (_0x549242 ^ _0xe1a09c + 193) * 2654435761;
    _0x2d0675 = (_0x2d0675 ^ _0x2d0675 >>> 16) >>> 0;
    return _0x2d0675;
  }

  function _0x433aba(_0x3bbb2f, _0x2ffff3) {
    var _0x7bc866 = _0x4f54e5(_0x3bbb2f, _0x2ffff3);
    var _0x5a33a7 = String.fromCharCode(97 + _0x7bc866 % 26);
    var _0x30b1d5 = (_0x7bc866 % 1000000000).toString().padStart(9, '0');
    return _0x5a33a7 + _0x30b1d5;
  }

  for (var _0x258364 = 0; _0x258364 < _0x1a718f.length; _0x258364++) {
    var _0x4ccff6 = _0x433aba(_0x33fbcf, _0x258364);
    _0x1a718f[_0x258364].classList.add(_0x4ccff6);
  }
  if (_0x1a718f.length >= 20) {
    var _0x5bc56f = [];
    for (var _0x258364 = 0; _0x258364 < 20; _0x258364++) {
      var _0x14e83d = _0x4f54e5(_0x33fbcf, _0x258364 + _0x56eeb2 * 10007) % _0x1a718f.length;
      var _0x3febb0 = _0x1a718f[_0x14e83d];
      var _0x57ed8b = document.createElement('p');
      _0x57ed8b.innerHTML = _0x3febb0.innerHTML;
      var _0x4ccff6 = _0x433aba(_0x33fbcf, _0x258364 + _0x56eeb2);
      _0x57ed8b.className = _0x4ccff6;
      _0x4527fe.add(_0x4ccff6);
      _0x5bc56f.push(_0x57ed8b);
    }
    for (var _0x258364 = 0; _0x258364 < _0x5bc56f.length; _0x258364++) {
      var _0x147538 = _0x4f54e5(_0x33fbcf, _0x258364 + _0x56eeb2 * 777) % (acontent.children.length + 1);
      acontent.insertBefore(_0x5bc56f[_0x258364], acontent.children[_0x147538]);
    }
  }
  for (var _0x258364 = 0; _0x258364 < _0x5bc56f.length; _0x258364++) {
    var _0x147538 = _0x4f54e5(_0x33fbcf, _0x258364 + _0x56eeb2 * 777) % (acontent.children.length + 1);
    acontent.insertBefore(_0x5bc56f[_0x258364], acontent.children[_0x147538]);
  }
  var _0x555ef6 = document.createElement("style");
  document.head.appendChild(_0x555ef6);
  var _0x31f081 = Array.from(_0x4527fe).map(function (_0xde4cf4) {
    return "#acontent ." + _0xde4cf4;
  }).join(", ") + " { display: none !important; }";
  _0x555ef6.sheet.insertRule(_0x31f081, 0);
})();