if not dirtyWord then
    dirtyWord = 
    {
        checkTextNumList = nil,--要检查的text字符编码
        checkTextList = nil,
    }
end
-------------------------------------------------
--把要检查的text分成一个一个字符编码（注意字符和汉字）
dirtyWord.cutWord = function(text)
    if not text then 
        TraceError("text is nil!!") 
        return 
    end 
    local times = 3
    local textLen = string.len(text)
    local textList = {}
    local lit = {}
    for i = 1 ,textLen do
        if string.byte(text,i) < 128 and times == 3 then--假如不是汉字
            table.insert(lit,string.byte(text,i))
            table.insert(textList,lit)
            lit = {}  
        else
            times = times - 1
            table.insert(lit,string.byte(text,i))
            if times == 0 then
                table.insert(textList,lit)
                lit = {}
                times = 3 
            end 
        end 
    end
    dirtyWord.checkTextNumList = textList
end

--开始检查，把脏字、词替换“*”
dirtyWord.checkWord = function(text)
    if not text then
        TraceError("dirtyWord.checkWord text is nli!!")
        return
    end

    --先把text转换成字符编码
    dirtyWord.cutWord(text)
    dirtyWord.checkTextList = text

    local count = #dirtyWord.checkTextNumList
    for i=1,count do    
        local list = dirtyWord.checkTextNumList[i]
        dirtyWord.subWord(list) 
    end
    return dirtyWord.checkTextList
end 

--判断这个字符是不是脏字符 如果是 返回* 还要注意词组~
--numList:字符编码列
dirtyWord.subWord = function(numList)
    if not numList then
        return
    end
    local newNumList = numList
    local wordLen = 1
    local dirtyWordLen = 0--长度
    if #numList == 1 then
        if conf.dirtyWordList[numList[1]] then
            local count = #conf.dirtyWordList[numList[1]]
            for i = 1,count do
                local word = conf.dirtyWordList[numList[1]][i]
                local wordLen = #word
                local xing = dirtyWord.getMessy()
                for k=2,wordLen do
                    xing = xing .. dirtyWord.getMessy()
                end 
                dirtyWord.checkTextList = string.gsub(dirtyWord.checkTextList,word,xing)
            end
        end 
    else
        local threeNum = numList[1] .. numList[2] .. numList[3]
        if conf.dirtyWordList[threeNum] then      
            local count = #conf.dirtyWordList[threeNum]
            for i = 1,count do
                local word = conf.dirtyWordList[threeNum][i]
                local wordLen = #word
                local xing = dirtyWord.getMessy()
                for k=4,wordLen,3 do
                    xing = xing .. dirtyWord.getMessy()
                end 
                dirtyWord.checkTextList = string.gsub(dirtyWord.checkTextList,word,xing)
            end
        end
    end
end
dirtyWord.getMessy = function()
	local messword = {[1] = "!&",[2] = "@",[3] = "#",[4] = "$",[5] = "%",[6] = "^$", [7] = "&",[8] = "*"}
	local num = math.random(1,8)
	return messword[num]
end

-----------------------------------------------
