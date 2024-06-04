--!Type(Module)

-- Function accepts list of alternative wait and functions
function Coroutine(...)
    args = {...}
    if(#args % 2 ~= 0) then print("Invalid paramters passed to coroutine, even number of parameters required. Interval followed by function") end
    _ExecuteCoroutineStep(args, 1)
end

function _ExecuteCoroutineStep(args,i)
    if(i < #args) then
        Timer.new(args[i], function()  
            args[i+1]()
            _ExecuteCoroutineStep(args,i+2)
        end, false)
    end
end