module exceptionhandling;

/**
   version(exceptionhandling_release_asserts)
   
   releases all assertXXXXs
*/

private {
	version(unittest) {
		import core.exception : AssertError;
		alias ExceptionType = AssertError;
	} else {
		alias ExceptionType = Exception;
	}

	import std.math : approxEqual;
	bool cmpFloat(T)(T tt, T tc) {
		return approxEqual(tt, tc);
	}

	bool cmpFloatNot(T)(T tt, T tc) {
		return !approxEqual(tt, tc);
	}

	bool cmpNot(T)(T tt, T tc) {
		return tt != tc;
	}

	bool cmp(T)(T tt, T tc) {
		return tt == tc;
	}

	bool cmpLess(T)(T tt, T tc) {
		return tt < tc;
	}

	bool cmpGreater(T)(T tt, T tc) {
		return tt > tc;
	}

	bool cmpLessEqual(T)(T tt, T tc) {
		return tt <= tc;
	}

	bool cmpGreaterEqual(T)(T tt, T tc) {
		return tt >= tc;
	}

	bool cmpLessEqualFloat(T)(T tt, T tc) {
		return tt < tc || approxEqual(tt, tc);
	}

	bool cmpGreaterEqualFloat(T)(T tt, T tc) {
		return tt > tc || approxEqual(tt, tc);
	}
}

/** Assert that `toTest` is equal to `toCompareAgainst`.
If `T` is a floating point `approxEqual` is used to compare the values.
`toTest` is returned if the comparision is correct.
If the comparision is incorrect an Exception is thrown. If assertEqual is used
in a unittest block an AssertError is thrown an Exception otherwise.
*/
auto ref T assertEqual(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	import std.traits : isFloatingPoint, isImplicitlyConvertible;
	static assert(isImplicitlyConvertible!(T,S));

	static if(isFloatingPoint!T) {
		return AssertImpl!(T,S, cmpFloat, "==")(toTest, toCompareAgainst,
				file, line
		);
	} else {
		return AssertImpl!(T,S, cmp, "==")(toTest, toCompareAgainst, file, line);
	}
}

/// ditto
auto ref T assertNotEqual(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	import std.traits : isFloatingPoint, isImplicitlyConvertible;
	static assert(isImplicitlyConvertible!(T,S));
	static if(isFloatingPoint!T) {
		return AssertImpl!(T,S, cmpFloatNot, "!=")(toTest, toCompareAgainst,
				file, line
		);
	} else {
		return AssertImpl!(T,S, cmpNot, "!=")(toTest, toCompareAgainst, file,
				line
		);
	}
}

/// ditto
auto ref T assertLess(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	import std.traits : isFloatingPoint, isImplicitlyConvertible;
	static assert(isImplicitlyConvertible!(T,S));
	return AssertImpl!(T,S, cmpLess, "<")(toTest, toCompareAgainst,
			file, line
	);
}

/// ditto
auto ref T assertGreater(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	import std.traits : isFloatingPoint, isImplicitlyConvertible;
	static assert(isImplicitlyConvertible!(T,S));
	return AssertImpl!(T,S, cmpGreater, ">")(toTest, toCompareAgainst,
			file, line
	);
}

/// ditto
auto ref T assertGreaterEqual(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	import std.traits : isFloatingPoint, isImplicitlyConvertible;
	static assert(isImplicitlyConvertible!(T,S));

	static if(isFloatingPoint!T) {
		return AssertImpl!(T,S, cmpGreaterEqualFloat, ">=")(toTest,
				toCompareAgainst, file, line
		);
	} else {
		return AssertImpl!(T,S, cmpGreaterEqual, ">=")(toTest,
				toCompareAgainst, file, line
		);
	}
}

/// ditto
auto ref T assertLessEqual(T,S)(auto ref T toTest, auto ref S toCompareAgainst,
		const string file = __FILE__, const int line = __LINE__)
{
	import std.traits : isFloatingPoint, isImplicitlyConvertible;
	static assert(isImplicitlyConvertible!(T,S));

	static if(isFloatingPoint!T) {
		return AssertImpl!(T,S, cmpLessEqualFloat, "<=")(toTest,
				toCompareAgainst, file, line
		);
	} else {
		return AssertImpl!(T,S, cmpLessEqual, "<=")(toTest,
				toCompareAgainst, file, line
		);
	}
}

private auto ref T AssertImpl(T,S,alias Cmp, string cmpMsg)(auto ref T toTest,
		auto ref S toCompareAgainst, const string file, const int line)
{
	import std.format : format;

	version(exceptionhandling_release_asserts) {
		return toTest;
	} else {
		bool cmpRslt = false;
		try {
			cmpRslt = Cmp(toTest, toCompareAgainst);
		} catch(Exception e) {
			throw new ExceptionType(
				format("Exception thrown while \"toTest(%s) " ~ cmpMsg
					~ " toCompareAgainst(%s)\"",
				toTest, toCompareAgainst), file, line, e
			);
		}

		if(!cmpRslt) {
			throw new ExceptionType(format("toTest(%s) " ~ cmpMsg ~
				" toCompareAgainst(%s) failed", toTest, toCompareAgainst), file, 
					line
			);
		}
		return toTest;
	}
}

unittest {
	import core.exception : AssertError;
	import std.exception : assertThrown;
	import std.meta : AliasSeq;

	foreach(T; AliasSeq!(byte,int,float,double)) {
		T zero = 0;
		T one = 1;
		T two = 2;

		T ret = assertEqual(one, one).assertGreater(zero).assertLess(two);
		cast(void)assertEqual(ret, one);
		ret = assertNotEqual(one, zero).assertGreater(zero).assertLess(two);
		cast(void)assertEqual(ret, one);
		ret = assertLessEqual(one, two)
			.assertGreaterEqual(zero)
			.assertEqual(one);
		cast(void)assertEqual(ret, one);

		cast(void)assertEqual(cast(const(T))one, one);
		cast(void)assertNotEqual(cast(const(T))one, zero);
		cast(void)assertEqual(one, cast(const(T))one);
		cast(void)assertNotEqual(one, cast(const(T))zero);

		assertThrown!AssertError(assertEqual(one, zero));
	}

	cast(void)assertEqual(1, 1);
	cast(void)assertNotEqual(1, 0);
}

unittest {
	import core.exception : AssertError;
	import std.exception : assertThrown;

	class Foo {
		int a;
		this(int a) { this.a = a; }
		override bool opEquals(Object o) {
			throw new Exception("Another test");
		}
	}

	auto f = new Foo(1);
	auto g = new Foo(1);

	assertThrown!AssertError(assertEqual(f, cast(Foo)null));
	assertThrown!AssertError(assertEqual(f, g));
}

/** Calls `exp` if `exp` does not throw the return value from `exp` is
returned, if `exp` throws the Exception is cought, a new Exception is
constructed with a message made of `args` space seperated and the previously
cought exception is nested in the newly created exception.
*/
auto expect(ET = Exception, F, int line = __LINE__, string file = __FILE__, Args...)
		(lazy F exp, lazy Args args)
{
	try {
		return exp();
	} catch(Exception e) {
		throw new ET(joinElem(args), file, line, e);
	}
}

private string joinElem(Args...)(lazy Args args) {
	import std.array : appender;
	import std.format : formattedWrite;

	auto app = appender!string();
	foreach(arg; args) {
		formattedWrite(app, "%s ", arg);
	}
	return app.data;
}

unittest {
	import std.string : indexOf;
	import std.exception : assertThrown;

	string barMsg = "Fun will thrown, I'm sure";
	string funMsg = "Hopefully this is true";

	void fun() {
		throw new Exception(funMsg);
	}

	void bar() {
		expect(fun(), barMsg);
	}

	bool func() {
		throw new Exception("e");
	}


	bool didThrow = false;
	try {
		bar();
	} catch(Exception e) {
		assert(e.msg.indexOf(barMsg) != -1, "\"" ~ e.msg ~ "\" " ~ barMsg);
		assert(e.next !is null);
		assert(e.next.msg.indexOf(funMsg) != -1, e.next.msg);
		didThrow = true;
	}

	assert(didThrow);

	assertThrown(assertEqual(func(), true));
}

auto ensure(ET = ExceptionType, E, int line = __LINE__,
		string file = __FILE__, Args...)(lazy E exp, Args args)
{
	try {
		auto rslt = exp();
		if(!rslt) {
			throw new ExceptionType(joinElem("Ensure failed", args), file, line);
		}
		return rslt;
	} catch(Exception e) {
		throw new ExceptionType(
			"Exception thrown will calling \"ensure\"", file, line, e
		);
	}
}

unittest {
	import core.exception : AssertError;
	//import std.exception : assertThrown, assertNotThrown;
	bool func() {
		throw new Exception("e");
	}

	auto e = assertThrown!AssertError(ensure(func()));
	assert(e.line == __LINE__ - 1);
	auto e2 = assertThrown!AssertError(ensure(false));
	assert(e2.line == __LINE__ - 1);
	bool b = assertNotThrown!AssertError(ensure(true));
	assert(b);
}

E assertThrown(E,T)(lazy T t, int line = __LINE__,
		string file = __FILE__)
{
	try {
		t();
	} catch(E e) {
		return e;
	}
	throw new ExceptionType("Exception of type " ~ E.stringof ~
			" was not thrown even though expected.", file, line
	);
}

auto assertNotThrown(E,T)(lazy T t, int line = __LINE__,
		string file = __FILE__)
{
	try {
		return t();
	} catch(E e) {
		throw new ExceptionType("Exception of type " ~ E.stringof ~
				" not caught unexceptionally", file, line
		);
	}
}
