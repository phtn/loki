run:
	odin run ph.odin -file

b:
	odin build ph.odin -out=build/ph -file

create:
	./build/ph create $(n)

testcmd:
	./build/ph test

buildcmd:
	./build/ph build

test:
	odin test ph.odin -file

clean:
	rm -rf build
