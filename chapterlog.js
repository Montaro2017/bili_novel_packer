(function () {
  var chapterId = typeof ReadParams !== "undefined" && ReadParams.chapterid ? parseInt(ReadParams.chapterid, 10) : null;
  if (!chapterId) {
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
      var nodeIdx = {
        node: node,
        idx: i
      };
      nodeIdxMap.push(nodeIdx);
    }
  }
  var length = nodeIdxMap.length;
  if (!length) {
    return;
  }
  function shuffle(array, seed) {
    var arrLength = array.length;
    seed = Number(seed);
    for (var i = arrLength - 1; i > 0; i--) {
      seed = (seed * 9302 + 49397) % 233280;
      var j = Math.floor(seed / 233280 * (i + 1));
      var tmp = array[i];
      array[i] = array[j];
      array[j] = tmp;
    }
    return array;
  }
  var indices = [];
  if (length > 20) {
    var fixed = [];
    var shuffled = [];
    for (var i = 0; i < length; i++) {
      if (i < 20) {
        fixed.push(i);
      } else {
        shuffled.push(i);
      }
    }
    var seed = Number(chapterId) * 137 + 233;
    shuffle(shuffled, seed);
    indices = fixed.concat(shuffled);
  } else {
    for (var i = 0; i < length; i++) {
      indices.push(i);
    }
  }
  var mapped = [];
  for (var i = 0; i < length; i++) {
    mapped[indices[i]] = nodeIdxMap[i].node;
  }
  var replacedIndex = 0;
  for (var i = 0; i < childNodes.length; i++) {
    var node = childNodes[i];
    if (node.nodeType === 1 && node.tagName.toLowerCase() === 'p' && node.innerHTML.replace(/\s+/g, '').length > 0) {
      childNodes[i] = mapped[replacedIndex];
      replacedIndex++;
    }
  }
  acontent.innerHTML = '';
  for (var i = 0; i < childNodes.length; i++) {
    if (childNodes[i]) {
      acontent.appendChild(childNodes[i]);
    }
  }
  var _0x55df03 = Array.prototype.slice.call(acontent.querySelectorAll('p'));
  if (!_0x55df03.length) {
    return;
  }
  var _0x18bb6d = new Set();
  function _0x4b32da(_0xfffe9d, _0x240fd8) {
    _0xfffe9d = Number(_0xfffe9d) || 0;
    _0x240fd8 = Number(_0x240fd8) || 0;
    var _0x2d6254 = (_0xfffe9d ^ _0x240fd8 + 193) * 2654435761;
    _0x2d6254 = (_0x2d6254 ^ _0x2d6254 >>> 16) >>> 0;
    return _0x2d6254;
  }
  function _0x409503(_0x5527e5, _0x211571) {
    var _0xd3b450 = _0x4b32da(_0x5527e5, _0x211571);
    var _0x4b5fcc = String.fromCharCode(97 + _0xd3b450 % 26);
    var _0x21d958 = (_0xd3b450 % 1000000000).toString().padStart(9, '0');
    return _0x4b5fcc + _0x21d958;
  }
  for (var _0x10daf4 = 0; _0x10daf4 < _0x55df03.length; _0x10daf4++) {
    var _0x2126bd = _0x409503(seed, _0x10daf4);
    _0x55df03[_0x10daf4].classList.add(_0x2126bd);
  }
  if (_0x55df03.length >= 20) {
    var _0x330e27 = [];
    for (var _0x10daf4 = 0; _0x10daf4 < 20; _0x10daf4++) {
      var _0x44e060 = _0x4b32da(seed, _0x10daf4 + length * 10007) % _0x55df03.length;
      var _0x390d77 = _0x55df03[_0x44e060];
      var _0x527c7e = document.createElement('p');
      _0x527c7e.innerHTML = _0x390d77.innerHTML;
      var _0x2126bd = _0x409503(seed, _0x10daf4 + length);
      _0x527c7e.className = _0x2126bd;
      _0x18bb6d.add(_0x2126bd);
      _0x330e27.push(_0x527c7e);
    }
    for (var _0x10daf4 = 0; _0x10daf4 < _0x330e27.length; _0x10daf4++) {
      var _0x32972f = _0x4b32da(seed, _0x10daf4 + length * 777) % (acontent.children.length + 1);
      acontent.insertBefore(_0x330e27[_0x10daf4], acontent.children[_0x32972f]);
    }
  }
  for (var _0x10daf4 = 0; _0x10daf4 < _0x330e27.length; _0x10daf4++) {
    var _0x32972f = _0x4b32da(seed, _0x10daf4 + length * 777) % (acontent.children.length + 1);
    acontent.insertBefore(_0x330e27[_0x10daf4], acontent.children[_0x32972f]);
  }
  var _0x1d9c0f = document.createElement("style");
  document.head.appendChild(_0x1d9c0f);
  var _0x4aea4d = Array.from(_0x18bb6d).map(function (_0x3d6b3) {
    return "#acontent ." + _0x3d6b3;
  }).join(", ") + " { display: none !important; }";
  _0x1d9c0f.sheet.insertRule(_0x4aea4d, 0);
})();