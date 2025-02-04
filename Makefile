run:
	odin run ph.odin -file

b:
	odin build ph.odin -out=build/ph -file

dev:
	@odin build ph.odin -out=build/ph -file
	./build/ph build

create:
	./build/ph create example

testcmd:
	./build/ph test

buildcmd:
	./build/ph build

test:
	@odin build ph.odin -out=build/ph -file
	./build/ph test

clean:
	rm -rf build
