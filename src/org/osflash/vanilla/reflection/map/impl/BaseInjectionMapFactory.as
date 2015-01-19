package org.osflash.vanilla.reflection.map.impl {
	import org.osflash.vanilla.MarshallingError;
	import org.osflash.vanilla.reflection.map.IInjectionMapFactory;
	import org.osflash.vanilla.reflection.map.InjectionDetail;
	import org.osflash.vanilla.reflection.map.InjectionMap;
	import org.osflash.vanilla.reflection.util.ReflectionUtil;

	import flash.system.System;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;

	public class BaseInjectionMapFactory implements IInjectionMapFactory {
		private static const METADATA_TAG : String = "Marshall";
		private static const TRANSIENT_TAG : String = "Transient";
		private static const FIELD : String = "field";
		private static const TYPE : String = "type";
		private static const FACTORY : String = "factory";
		private static const METADATA : String = "metadata";
		private static const CONSTRUCTOR : String = "constructor";
		private static const VARIABLE : String = "variable";
		private static const METHOD : String = "method";
		private static const ACCESSOR : String = "accessor";
		private static const PARAMETER : String = "parameter";
		private static const ARG : String = "arg";
		private static const TRUE : String = "true";
		private static const READONLY : String = "readonly";

		public function buildForType(clazz : Class) : InjectionMap {
			const factory : XML = describeType(clazz)[FACTORY][0];
			const map : InjectionMap = new InjectionMap();

			if (ReflectionUtil.isVector(clazz)) {
				map.typedHint = ReflectionUtil.getVectorType(clazz);
			} else {
				addCtorMapping(factory, map);
				addFieldsMapping(factory, map);
				addMethodsMapping(factory, map);
			}

			System.disposeXML(factory);

			return map;
		}

		private function addCtorMapping(factory : XML, map : InjectionMap) : void {
			var constructor : XML = factory[CONSTRUCTOR][0];
			var metaData : XML = factory[METADATA].(@name == METADATA_TAG)[0];

			var detail : InjectionDetail;
			if (metaData && constructor) {
				var fields : XMLList = metaData[ARG].(@key == FIELD);
				var constructorParameters : XMLList = constructor[PARAMETER];

				var field : XML;
				var parameter : XML;

				if (fields.length() > 0) {
					var i : uint;
					for (i = 0; i < fields.length(); i++) {
						field = fields[i];
						parameter = constructorParameters.(@index == (i + 1))[0];

						if (!parameter) {
							throw new MarshallingError("Missing required field for constructor", MarshallingError.MISSING_REQUIRED_FIELD);
						}

						var typeDefinition : String = parameter.@type;
						var type : Class = getDefinitionByName(typeDefinition) as Class;
						var isRequired : Boolean = parameter.@optional != TRUE;

						var typedHint : Class = null;
						if (ReflectionUtil.isVector(typeDefinition)) {
							typedHint = ReflectionUtil.getVectorType(typeDefinition);
						}

						detail = new InjectionDetail(field.@value, type, isRequired, typedHint);

						map.addConstructorField(detail);
					}
				}
			}
		}

		private function addFieldsMapping(factory : XML, map : InjectionMap) : void {
			var variables : XMLList = factory[VARIABLE] + factory[ACCESSOR];
			var variable : XML;

			const length : uint = variables.length();
			if (length > 0) {
				for each (variable in variables) {
					var isTransient : Boolean = variable[METADATA].(@name == TRANSIENT_TAG).length() > 0 || variable.@access == READONLY;

					if (isTransient) continue;

					var typeDefinition : String = variable.@type;
					var type : Class = getDefinitionByName(typeDefinition) as Class;
					var typedHint : Class = null;
					var fieldName : String = variable.@name;
					var sourceFieldName : String = fieldName;

					var metadata : XML = variable[METADATA].(@name == METADATA_TAG)[0];
					if (metadata) {
						var field : XML = metadata[ARG].(@key == FIELD)[0];
						if (field) {
							sourceFieldName = field.@value;
						}
					}
					if (ReflectionUtil.isVector(typeDefinition)) {
						typedHint = ReflectionUtil.getVectorType(typeDefinition);
					} else if (type == Array) {
						if (metadata) {
							var typeField : XML = metadata[ARG].(@key == TYPE)[0];
							if (typeField) {
								typedHint = getDefinitionByName(typeField.@value) as Class;
							}
						}
					}

					var detail : InjectionDetail = new InjectionDetail(sourceFieldName, type, false, typedHint);
					map.addField(fieldName, detail);
				}
			}
		}

		private function addMethodsMapping(factory : XML, map : InjectionMap) : void {
			var metadataNodes : XMLList = factory[METHOD][METADATA].(@name == METADATA_TAG);
			if (metadataNodes.length() > 0) {
				for each (var metadata : XML in metadataNodes) {
					var method : XML = metadata.parent();
					var fields : XMLList = metadata[ARG].(@key == FIELD);
					var parameters : XMLList = method[PARAMETER];

					var field : XML;
					var parameter : XML;

					if (fields.length() > 0) {
						var i : uint;
						for (i = 0; i < fields.length(); i++) {
							field = fields[i];
							parameter = parameters.(@index == (i + 1))[0];

							if (!parameter) {
								throw new MarshallingError("Missing required field for method", MarshallingError.MISSING_REQUIRED_FIELD);
							}

							var typeDefinition : String = parameter.@type;
							var type : Class = getDefinitionByName(typeDefinition) as Class;

							var typedHint : Class = null;
							if (ReflectionUtil.isVector(typeDefinition)) {
								typedHint = ReflectionUtil.getVectorType(typeDefinition);
							}

							map.addMethod(method.@name, new InjectionDetail(field.@value, type, false, typedHint));
						}
					}
				}
			}
		}
	}
}
