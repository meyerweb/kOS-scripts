// Bezier Tool Canvas Commands Generator
//
// history:
// - 04/03/2011: born!
//
// @author Victoria Kirst

///////////////////////////////////////////////////////////////////////////////
// Globals
///////////////////////////////////////////////////////////////////////////////
var gCanvas;
var gCtx;

var gBackCanvas;
var gBackCtx;

var gBezierPath;

var Mode = {
  kAdding : {value: 0, name: "Adding"}, 
  kSelecting : {value: 1, name: "Selecting"}, 
  kDragging: {value: 2, name: "Dragging"}, 
  kRemoving : {value: 3, name: "Removing"}, 
};

var gState;
var gBackgroundImg;

var WIDTH;
var HEIGHT;

///////////////////////////////////////////////////////////////////////////////
// Functions 
///////////////////////////////////////////////////////////////////////////////

// Main
window.onload = function() {
  gCanvas = document.getElementById('paintme');
  gCtx = gCanvas.getContext('2d');
  HEIGHT = gCanvas.height;
  WIDTH = gCanvas.width;
  
  gBackCanvas = document.createElement('canvas');
  gBackCanvas.height = HEIGHT;
  gBackCanvas.width = WIDTH;
  gBackCtx = gBackCanvas.getContext('2d');

  gState = Mode.kAdding;

  gCanvas.addEventListener("mousedown", handleDown, false);    
  gCanvas.addEventListener("mouseup", handleUp, false);    


  var selectButton = document.getElementById('selectMode');
  selectButton.addEventListener("click", function() {
      gState = Mode.kSelecting;
    }, false);

  var addButton = document.getElementById('addMode');
  addButton.addEventListener("click", function() {
      gState = Mode.kAdding;
    }, false);

  var removeButton = document.getElementById('removeMode');
  removeButton.addEventListener("click", function() {
      gState = Mode.kRemoving;
    }, false);

  var lockButton = document.getElementById('lockControl');
  lockButton.addEventListener("click", function() {
      ControlPoint.prototype.syncNeighbor = lockButton.checked;
    }, false);

  var clearButton = document.getElementById('clear');
  clearButton.addEventListener('click', function() {
      var doDelete = confirm('r u sure u want to delete all');
      if (doDelete) {
        gBezierPath = null;
        gBackCtx.clearRect(0, 0, WIDTH, HEIGHT);
        gCtx.clearRect(0, 0, WIDTH, HEIGHT);
      }
 
    }, false);

  var setSrcButton = document.getElementById('addImgSrc');
  setSrcButton.addEventListener('click', function() {
    var input = document.getElementById('imageSrc');
    gBackgroundImg = document.createElement('img');

    // No image if invalid path
    gBackgroundImg.onerror = function() {
      gBackgroundImg = null;
    };
    gBackgroundImg.src = input.value;
    render();
    
    input.value = '';
    
    }, false);

};

// Modified from http://diveintohtml5.org/examples/halma.js
function getMousePosition(e) {
    var x;
    var y;
    if (e.pageX != undefined && e.pageY != undefined) {
      x = e.pageX;
      y = e.pageY;
    }
    else {
      x = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
      y = e.clientY + document.body.scrollTop + document.documentElement.scrollTop;
    }
    x -= gCanvas.offsetLeft;
    y -= gCanvas.offsetTop;
    
    return new Point(x, y);
}

function handleDown(e) {
  var pos = getMousePosition(e);
  switch(gState) {
    case Mode.kAdding:
      handleDownAdd(pos);
      break;
    case Mode.kSelecting:
      handleDownSelect(pos);
      break;
    case Mode.kRemoving:
      handleDownRemove(pos);
      break;
  }
}

function handleDownAdd(pos) {
  if (!gBezierPath)
    gBezierPath = new BezierPath(pos);
  else {
    // If this was probably a selection, change to
    // select/drag mode
    if (handleDownSelect(pos))
      return;
    gBezierPath.addPoint(pos);
  }
  render();
}

// Return true/false if dragging mode
function handleDownSelect(pos) {
  if (!gBezierPath)
    return false;
  var selected = gBezierPath.selectPoint(pos);
  if (selected) {
    gState = Mode.kDragging;
    gCanvas.addEventListener("mousemove", updateSelected, false);
    return true;
  }
  return false;
}

function handleDownRemove(pos) {
  if (!gBezierPath)
    return;
  var deleted = gBezierPath.deletePoint(pos);
  if (deleted)
    render();
}

function updateSelected(e) {
  var pos = getMousePosition(e);
  gBezierPath.updateSelected(pos);
  render();
}

function handleUp(e) {
  if (gState == Mode.kDragging) {
    gCanvas.removeEventListener("mousemove", updateSelected, false);
    gBezierPath.clearSelected();
    gState = Mode.kSelecting;
  }
}

function render() {
  gBackCtx.clearRect(0, 0, WIDTH, HEIGHT);
  gCtx.clearRect(0, 0, WIDTH, HEIGHT);
  if (gBackgroundImg)
    gBackCtx.drawImage(gBackgroundImg, 0, 0);
  if (gBezierPath) {
    gBezierPath.draw(gBackCtx);
    var codeBox = document.getElementById('putJS');
    codeBox.innerHTML = gBezierPath.toJSString();	
  }
  gCtx.drawImage(gBackCanvas, 0, 0);
}

///////////////////////////////////////////////////////////////////////////////
// Classes
///////////////////////////////////////////////////////////////////////////////
function Point(newX, newY)
{
  var my = this;
  var xVal = newX;
  var yVal = newY;

  var RADIUS = 3;
  var SELECT_RADIUS = RADIUS + 2;
 
  this.x = function () {
    return xVal;
  }

  this.y = function () {
    return yVal;
  }

  this.set = function(x, y) {
    xVal = x;
    yVal = y;
  };

  this.drawSquare = function(ctx) {
    ctx.fillRect(xVal - RADIUS, yVal - RADIUS, RADIUS * 2, RADIUS * 2);     
  };
  
  this.computeSlope = function(pt) {
    return (pt.y() - yVal) / (pt.x() - xVal);
  };

  this.contains = function(pt) {
    var xInRange = pt.x() >= xVal - SELECT_RADIUS && pt.x() <= xVal + SELECT_RADIUS;
    var yInRange = pt.y() >= yVal - SELECT_RADIUS && pt.y() <= yVal + SELECT_RADIUS;
    return xInRange && yInRange;
  };
  
  this.offsetFrom = function(pt) {
    return {
      xDelta : pt.x() - xVal,
      yDelta : pt.y() - yVal,
    };
  };

  this.translate = function(xDelta, yDelta) {
    xVal += xDelta;
    yVal += yDelta;
  };
}

function ControlPoint(angle, magnitude, owner, isFirst) {
  var my = this;

  var _angle = angle;
  var _magnitude = magnitude;

  // Pointer to the line segment to which this belongs.
  var _owner = owner;
  var _isFirst = isFirst; 

  this.setAngle = function(deg) {
    // don't update neighbor in risk of infinite loop!
    // TODO fixme fragile
    if (_angle != deg)
      _angle = deg;
  }

  this.origin = function origin() {
    var line = null;
    if (_isFirst)
      line = _owner.prev;
    else
      line = _owner;
    if (line)
      return new Point(line.pt.x(), line.pt.y());
    return null;
  }

  // Returns the Point at which the knob is located.
  this.asPoint = function() {
    return new Point(my.x(), my.y());
  };

  this.x = function () {
    return  my.origin().x() + my.xDelta();
  }

  this.y = function () {
    return my.origin().y() + my.yDelta();
  }

  this.xDelta = function() {
    return _magnitude * Math.cos(_angle);
  }

  this.yDelta = function() {
    return _magnitude * Math.sin(_angle);
  }

  function computeMagnitudeAngleFromOffset(xDelta, yDelta) {
    _magnitude = Math.sqrt(Math.pow(xDelta, 2) + Math.pow(yDelta, 2));
    var tryAngle = Math.atan(yDelta /xDelta);
    if (!isNaN(tryAngle)) {
      _angle = tryAngle;
      if (xDelta < 0)
        _angle += Math.PI
    }
  }

  this.translate = function(xDelta, yDelta) {
    var newLoc = my.asPoint();
    newLoc.translate(xDelta, yDelta);
    var dist = my.origin().offsetFrom(newLoc);
    computeMagnitudeAngleFromOffset(dist.xDelta, dist.yDelta);
    if (my.__proto__.syncNeighbor)
      updateNeighbor();
  };

  function updateNeighbor() {
    var neighbor = null;
    if (_isFirst && _owner.prev)
      neighbor = _owner.prev.ctrlPt2;
    else if (!_isFirst && _owner.next)
      neighbor = _owner.next.ctrlPt1;
    if (neighbor)
      neighbor.setAngle(_angle + Math.PI);
  }

  this.contains = function(pt) {
    return my.asPoint().contains(pt);
  }

  this.offsetFrom = function(pt) {
    return my.asPoint().offsetFrom(pt);
  }

  this.draw = function(ctx) {
    ctx.save();
    ctx.fillStyle = 'gray';
    ctx.strokeStyle = 'gray';  
    ctx.beginPath();
    var startPt = my.origin();
    var endPt = my.asPoint();
    ctx.moveTo(startPt.x(), startPt.y());
    ctx.lineTo(endPt.x(), endPt.y());
    ctx.stroke();
    endPt.drawSquare(ctx);
    ctx.restore();
  }

  // When Constructed
  if (my.__proto__.syncNeighbor)
    updateNeighbor();
}

// Static variable dictacting if neighbors must be kept in sync.
ControlPoint.prototype.syncNeighbor = true;

function LineSegment(pt, prev) {
  var my = this;

  // Path point.
  this.pt;
  // Control point 1.
  this.ctrlPt1; 
  // Control point 2.
  this.ctrlPt2;

  // Next LineSegment in path
  this.next;
  // Previous LineSegment in path
  this.prev;

  // Specific point on the LineSegment that is selected.
  this.selectedPoint;

  init();

  this.draw = function(ctx) {
    my.pt.drawSquare(ctx);
    // Draw control points if we have them
    if (my.ctrlPt1)
      my.ctrlPt1.draw(ctx);
    if (my.ctrlPt2)
      my.ctrlPt2.draw(ctx);

    // If there are at least two points, draw curve.
    if (my.prev)
      drawCurve(ctx, my.prev.pt, my.pt, my.ctrlPt1, my.ctrlPt2);
  }

  this.toJSString = function() {
    if (!my.prev)
      return '  ctx.moveTo(' + Math.round(my.pt.x()) + ' + xoff, ' + Math.round(my.pt.y()) + ' + yoff);';
    else {
      var ctrlPt1x = 0;
      var ctrlPt1y = 0;
      var ctrlPt2x = 0;
      var ctlrPt2y = 0;
      var x = 0;
      var y = 0;

      if (my.ctrlPt1) {
        ctrlPt1x = Math.round(my.ctrlPt1.x());
        ctrlPt1y = Math.round(my.ctrlPt1.y());
      }

      if (my.ctrlPt2) {
        ctrlPt2x = Math.round(my.ctrlPt2.x());
        ctrlPt2y = Math.round(my.ctrlPt2.y());
      }
      if (my.pt) {
        x = Math.round(my.pt.x());
        y = Math.round(my.pt.y());
      }

      return '  ctx.bezierCurveTo(' + ctrlPt1x + ' + xoff, ' +
              ctrlPt1y + ' + yoff, ' +
              ctrlPt2x + ' + xoff, ' +
              ctrlPt2y + ' + yoff, ' +
              x + ' + xoff, ' +
              y + ' + yoff);';
    }    
  }

  this.findInLineSegment = function(pos) {
    if (my.pathPointIntersects(pos)) {
      my.selectedPoint = my.pt;
      return true;
    } else if (my.ctrlPt1 && my.ctrlPt1.contains(pos)) {
      my.selectedPoint = my.ctrlPt1;
      return true;
    } else if (my.ctrlPt2 && my.ctrlPt2.contains(pos)) {
      my.selectedPoint = my.ctrlPt2;
      return true;
    }
    return false;
  }

  this.pathPointIntersects = function(pos) {
    return my.pt && my.pt.contains(pos);
  }

  this.moveTo = function(pos) {
    var dist = my.selectedPoint.offsetFrom(pos);
    my.selectedPoint.translate(dist.xDelta, dist.yDelta);
  };

  function drawCurve(ctx, startPt, endPt, ctrlPt1, ctrlPt2) {
    ctx.save();
    ctx.fillStyle = 'black';
    ctx.strokeStyle = 'black';  
    ctx.beginPath();
    ctx.moveTo(startPt.x(), startPt.y());
    ctx.bezierCurveTo(ctrlPt1.x(), ctrlPt1.y(), ctrlPt2.x(), ctrlPt2.y(), endPt.x(), endPt.y());
    ctx.stroke();
    ctx.restore();
  }

  function init() {
    my.pt = pt;
    my.prev = prev;

    if (my.prev) {

      // Make initial line straight and with controls of length 15.
      var slope = my.pt.computeSlope(my.prev.pt);
      var angle = Math.atan(slope);
    
      if (my.prev.pt.x() > my.pt.x())
        angle *= -1;
    
      my.ctrlPt1 = new ControlPoint(angle + Math.PI, 15, my, true);
      my.ctrlPt2 = new ControlPoint(angle, 15, my, false);
    }
  };
}

function BezierPath(startPoint)
{
  var my = this;
  // Beginning of BezierPath linked list.
  this.head = null;
  // End of BezierPath linked list
  this.tail = null;
  // Reference to selected LineSegment
  var selectedSegment;

  this.addPoint = function(pt) {
    var newPt = new LineSegment(pt, my.tail);
    if (my.tail == null) {
      my.tail = newPt;
      my.head = newPt;
    } else {
      my.tail.next = newPt;
      my.tail = my.tail.next;
    }
    return newPt;
  };

  // Must call after add point, since init uses
  // addPoint
  // TODO: this is a little gross
  init();
  
  this.draw = function(ctx) {
    if (my.head == null)
      return;

    var current = my.head;
    while (current != null) {
      current.draw(ctx);
      current = current.next;
    }
  };

  // returns true if point selected
  this.selectPoint = function(pos) {
    var current = my.head;
    while (current != null) {
      if (current.findInLineSegment(pos)) {
      	selectedSegment = current;
      	return true;
      }
      current = current.next;
    }
    return false;
  }

  // returns true if point deleted
  this.deletePoint = function(pos) {
    var current = my.head;
    while (current != null) {
      if (current.pathPointIntersects(pos)) {
      	var toDelete = current;
        var leftNeighbor = current.prev;
        var rightNeighbor = current.next;

        // Middle case
        if (leftNeighbor && rightNeighbor) {
          leftNeighbor.next = rightNeighbor;
          rightNeighbor.prev = leftNeighbor
        }
        // HEAD CASE
        else if (!leftNeighbor) {
          my.head = rightNeighbor;
          if (my.head) {
            rightNeighbor.ctrlPt1 = null;
            rightNeighbor.ctrlPt2 = null;
            my.head.prev = null;
          }
          else 
            my.tail = null;
        }
        // TAIL CASE
        else if (!rightNeighbor) {
          my.tail = leftNeighbor;
          if (my.tail)
            my.tail.next = null;
          else 
            my.head = null;
        }
      	return true;
      }
      current = current.next;
    }
    return false;
  }

  this.clearSelected = function() {
    selectedSegment = null;
  }

  this.updateSelected = function(pos) {
    selectedSegment.moveTo(pos);
  }

  this.toJSString = function() {
    var myString = 
      ['function drawShape(ctx, xoff, yoff) {',
       '  ctx.beginPath();',
      ];
    
    var current = my.head;
    while (current != null) {
      myString.push(current.toJSString());
      current = current.next;
    }
		myString.push('  ctx.stroke();');
		myString.push('}');
		return myString.join('\n');
  }

  function init() {
    my.addPoint(startPoint);
  };
}
