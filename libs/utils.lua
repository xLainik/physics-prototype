
function getAngle(x1,y1, x2,y2)
	return math.atan2(y2-y1, x2-x1)
end

function getDistance(x1,y1, x2,y2)
	return math.sqrt((y2-y1)^2 + (x2-x1)^2)
end

function dotProduct(x1,y1, x2,y2)
	return x1*x2 + y1*y2
end

function getSign(number)
	return number > 0 and 1 or (number == 0 and 0 or -1)
end

function clamp(x, min, max)
  return x < min and min or (x > max and max or x)
end