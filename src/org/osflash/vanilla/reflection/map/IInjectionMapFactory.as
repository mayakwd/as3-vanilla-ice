package org.osflash.vanilla.reflection.map {

	public interface IInjectionMapFactory {
		function buildForType(type : Class) : InjectionMap;
	}
}
