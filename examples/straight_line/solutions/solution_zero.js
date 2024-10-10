var __interpretation_started_timestamp__;
var pi = 3.141592653589793;

var main = function()
{
	__interpretation_started_timestamp__ = Date.now();
	
	brick.motor(M3).setPower(100);
	brick.motor(M4).setPower(100);
	
	script.wait(1250);
	
	brick.motor(M1).brake();
	brick.motor(M2).brake();
	brick.motor(M3).brake();
	brick.motor(M4).brake();
	
	return;
}
