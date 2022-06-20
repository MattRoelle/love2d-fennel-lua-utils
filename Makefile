lutils.lua: 
	fennel --require-as-include -c lutils/init.fnl > lutils.lua

clean:
	rm lutils.lua

