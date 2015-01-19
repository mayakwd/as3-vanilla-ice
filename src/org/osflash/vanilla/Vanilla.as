package org.osflash.vanilla {
	import org.osflash.vanilla.reflection.map.IInjectionMapFactory;
	import org.osflash.vanilla.reflection.map.InjectionDetail;
	import org.osflash.vanilla.reflection.map.InjectionMap;
	import org.osflash.vanilla.reflection.map.impl.BaseInjectionMapFactory;
	import org.osflash.vanilla.reflection.util.ReflectionUtil;

	import flash.utils.Dictionary;

	public class Vanilla {
		private static const TRUE : String = "true";
		
		private var _factory : IInjectionMapFactory;
		private var _hash : Dictionary = new Dictionary();
		private var _allowSimpleTypesConversion : Boolean = true;

		public function Vanilla(factory : IInjectionMapFactory = null) {
			_factory = factory || new BaseInjectionMapFactory();
		}

		public function get allowSimpleTypesConversion() : Boolean {
			return _allowSimpleTypesConversion;
		}

		public function set allowSimpleTypesConversion(allowSimpleTypesConversion : Boolean) : void {
			_allowSimpleTypesConversion = allowSimpleTypesConversion;
		}

		public function clearHash() : void {
			_hash = new Dictionary();
		}

		public function dispose() : void {
			_hash = null;
			_factory = null;
		}

		/**
		 * Attempts to extract properties from the supplied source object into an instance of the supplied targetType.
		 * 
		 * @param source		Object which contains properties that you wish to transfer to a new instance of the 
		 * 						supplied targetType Class.
		 * @param targetType	The target Class of which an instance will be returned.
		 * @return				An instance of the supplied targetType containing all the properties extracted from
		 * 						the supplied source object.
		 */
		public function extract(source : Object, targetType : Class) : * {
			// Catch the case where we've been asked 8to extract a value which is already of the intended targetType;
			// this can often happen when Vanilla is recursing, in which case there is nothing to do.
			if (source is targetType) {
				return source;
			}

			var target : *;

			const targetIsVector : Boolean = ReflectionUtil.isVector(targetType);

			if (!targetIsVector && ReflectionUtil.isSimpleObject(source) && _allowSimpleTypesConversion) {
				return convertSimpleType(source, targetType);
			}
			
			// Construct an InjectionMap which tells us how to inject fields from the source object into
			// the Target class.
			var injectionMap : InjectionMap;

			if (targetType in _hash) {
				injectionMap = _hash[targetType];
			} else {
				injectionMap = _hash[targetType] = _factory.buildForType(targetType);
			}

			// Create a new instance of the targetType; and then inject the values from the source object into it
			
			if (targetIsVector) {
				return extractVector(source, targetType, injectionMap.typedHint);
			}

			target = ReflectionUtil.newInstance(targetType, fetchConstructorArgs(source, injectionMap.getConstructorFields()));
			
			injectFields(source, target, injectionMap);
			injectMethods(source, target, injectionMap);

			return target;
		}

		private function parseNumber(source : String, type : Class) : * {
			if (source.substr(0, 2) == "0x") {
				return type(parseInt(source.substr(2), 16));
			} else if (type is uint || type is int) {
				return type(parseInt(source));
			} else
				return type(parseFloat(source));
		}

		/**
		 * @param target		Target where you wish to update properties
		 * @param source		Object which contains properties that you wish to update in target 
		 * @return				An target with update properties
		 */
		public function update(target : *, source : Object) : * {
			const targetType : Class = Object(target).constructor as Class;
			if (!targetType) throw TypeError("Can't extract type for \"updateItem\"");

			var injectionMap : InjectionMap;

			if (targetType in _hash) {
				injectionMap = _hash[targetType];
			} else {
				injectionMap = _hash[targetType] = _factory.buildForType(targetType);
			}

			injectFields(source, target, injectionMap);
			injectMethods(source, target, injectionMap);

			return target;
		}

		private function fetchConstructorArgs(source : Object, constructorFields : Array) : Array {
			const result : Array = [];
			for (var i : uint = 0; i < constructorFields.length; i++) {
				result.push(extractValue(source, constructorFields[i]));
			}
			return result;
		}

		private function injectFields(source : Object, target : *, injectionMap : InjectionMap) : void {
			const fieldNames : Array = injectionMap.getFieldNames();
			for each (var fieldName : String in fieldNames) {
				var injectionDetail : InjectionDetail = injectionMap.getField(fieldName);
				target[fieldName] = extractValue(source, injectionDetail);
			}
		}

		private function injectMethods(source : Object, target : *, injectionMap : InjectionMap) : void {
			const methodNames : Array = injectionMap.getMethodsNames();
			for each (var methodName : String in methodNames) {
				const values : Array = [];
				for each (var injectionDetail : InjectionDetail in injectionMap.getMethod(methodName)) {
					values.push(extractValue(source, injectionDetail));
				}
				(target[methodName] as Function).apply(null, values);
			}
		}

		private function extractValue(source : Object, injectionDetail : InjectionDetail) : * {
			var value : * = source[injectionDetail.name];

			// Is this a required injection?
			if (injectionDetail.isRequired && value === undefined) {
				throw new MarshallingError("Required value " + injectionDetail + " does not exist in the source object.", MarshallingError.MISSING_REQUIRED_FIELD);
			}

			if (value) {
				// automatically coerce simple types.
				if (!ReflectionUtil.isSimpleObject(value)) {
					value = extract(value, injectionDetail.type);
				}
				
				// Collections are harder, we need to coerce the contents. 
				else if (value is Array) {
					if (ReflectionUtil.isVector(injectionDetail.type)) {
						value = extractVector(value, injectionDetail.type, injectionDetail.arrayTypeHint);
					} else if (injectionDetail.arrayTypeHint) {
						value = extractTypedArray(value, injectionDetail.arrayTypeHint);
					}
				}

				if (!(value is injectionDetail.type)) {
					if (_allowSimpleTypesConversion) {
						value = convertSimpleType(value, injectionDetail.type);
					} else {
						throw new MarshallingError("Could not coerce `" + injectionDetail.name + "` (value: " + value + " <" + Object(value).constructor + "]>) from source object to " + injectionDetail.type + " on target object", MarshallingError.TYPE_MISMATCH);
					}
				}
			}

			return value;
		}

		private function convertSimpleType(value : *, type : Class) : * {
			if (value is String && (type == uint || type == int || type == Number)) {
				return parseNumber(value, type);
			} else if (value is String && type == Boolean) {
				return String(value).toLowerCase() == TRUE; 
			} else
				return type(value);
		}

		private function extractTypedArray(source : Array, targetClassType : Class) : Array {
			const result : Array = new Array(source.length);
			for (var i : uint = 0; i < source.length; i++) {
				result[i] = extract(source[i], targetClassType);
			}
			return result;
		}

		
		private static const LENGTH : String = "length";
		private function extractVector(source : Object, targetVectorClass : Class, targetClassType : Class) : * {
			const result : * = new targetVectorClass();
			const length : int = source[LENGTH];
			
			for (var i : uint = 0; i < length; i++) {
				if (ReflectionUtil.isVector(targetClassType)) {
					const type : Class = ReflectionUtil.getVectorType(targetClassType);
					result[i] = extractVector(source[i], targetClassType, type);
				} else {
					result[i] = extract(source[i], targetClassType);
				}
			}
			return result;
		}
	}
}
