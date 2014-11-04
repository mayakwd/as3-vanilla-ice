package org.osflash.vanilla.reflection.util {
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	public class ReflectionUtil {
		private static const VECTOR : String = "__AS3__.vec::Vector";

		public static function isVector(value : *) : Boolean {
			return extractTypeName(value).indexOf(VECTOR) == 0;
		}

		private static function extractTypeName(value : *) : String {
			return value is String ? value : getQualifiedClassName(value);
		}

		public static function getVectorType(value : *) : Class {
			const index : int = VECTOR.length + 2;

			var typeName : String = extractTypeName(value);
			typeName = typeName.substr(index, typeName.length - index - 1);

			return getDefinitionByName(typeName) as Class;
		}

		public static function isSimpleObject(object : Object) : Boolean {
			switch (typeof(object)) {
				case "number":
				case "string":
				case "boolean":
					return true;
				case "object":
					return (object is Date) || (object is Array);
			}

			return false;
		}

		public static function newInstance(type : Class, ctorArgs : Array) : * {
			if (!ctorArgs || ctorArgs.length == 0) return new type();

			if (ctorArgs.length > 10)
				throw new ArgumentError('Too much arguments was passed (max. 10).');

			switch (ctorArgs.length) {
				case 1 :
					return new type(ctorArgs[0]);
				case 2 :
					return new type(ctorArgs[0], ctorArgs[1]);
				case 3 :
					return new type(ctorArgs[0], ctorArgs[1], ctorArgs[2]);
				case 4 :
					return new type(ctorArgs[0], ctorArgs[1], ctorArgs[2], ctorArgs[3]);
				case 5 :
					return new type(ctorArgs[0], ctorArgs[1], ctorArgs[2], ctorArgs[3], ctorArgs[4]);
				case 6 :
					return new type(ctorArgs[0], ctorArgs[1], ctorArgs[2], ctorArgs[3], ctorArgs[4], ctorArgs[5]);
				case 7 :
					return new type(ctorArgs[0], ctorArgs[1], ctorArgs[2], ctorArgs[3], ctorArgs[4], ctorArgs[5], ctorArgs[6]);
				case 8 :
					return new type(ctorArgs[0], ctorArgs[1], ctorArgs[2], ctorArgs[3], ctorArgs[4], ctorArgs[5], ctorArgs[6], ctorArgs[7]);
				case 9 :
					return new type(ctorArgs[0], ctorArgs[1], ctorArgs[2], ctorArgs[3], ctorArgs[4], ctorArgs[5], ctorArgs[6], ctorArgs[7], ctorArgs[8]);
				case 10 :
					return new type(ctorArgs[0], ctorArgs[1], ctorArgs[2], ctorArgs[3], ctorArgs[4], ctorArgs[5], ctorArgs[6], ctorArgs[7], ctorArgs[8], ctorArgs[9]);
			}
			return null;
		}
	}
}
