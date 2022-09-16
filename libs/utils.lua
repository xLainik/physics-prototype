
-- Trig and vector operations --------------------------------------

function getAngle(x1,y1, x2,y2)
	return math.atan2(y2-y1, x2-x1)
end

function getDistance(x1,y1, x2,y2)
	 return math.sqrt((y2-y1)^2 + (x2-x1)^2)
end

function getLenght(x, y)
	return math.sqrt(x^2 + y^2)
end

function sumVector(x1,y1, x2,y2)
	return x1+x2, y1+y2
end

function difVector(x1,y1, x2,y2)
	return x1-x2, y1-y2
end

function normalizeVector(x, y)
	local lenght = getLenght(x, y)
	return x/lenght, y/lenght
end

function scaleVector(x, y, scalar)
	return x*scalar, y*scalar
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

function getIndex(table_, element)
	for index, value in ipairs(table_) do
       if value == element then
            return index
       end
    end
end

-- Data manipulation ----------------------------------------------------

function getTable(string_, sep)
	local words = {}
    for word in string.gmatch(string_, sep or "([^%s]+)") do
        table.insert(words, tonumber(word) or word)
    end
    return words
end

function getFormatedTable(table_)
	local new_table = {}
    for _, element in ipairs(table_) do
        -- Check if it is a number or a string
        table.insert(new_table, tonumber(element) or element)
    end
    if #new_table == 1 then return new_table[1] end
    return new_table
end