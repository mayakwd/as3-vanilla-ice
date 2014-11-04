package org.osflash.vanilla.testdata
{
	public class StringArrayList
	{
		private var _strings : Array;
		
		[Marshall(field="strings", type="String")]
		public function setStrings(value : Array) : void {
			_strings = value;
		}
		
		public function getStrings() : Array {
			return _strings;
		}
	}
}
