
--
-- Copyright (C) 2017-2018 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

class DLib.Set
	new: =>
		@values = {}

	add: (object) =>
		return false if object == nil
		for i, val in ipairs @values
			if val == object
				return false

		return table.insert(@values, object)

	addArray: (objects) => @add(object) for object in *objects

	has: (object) =>
		return false if object == nil
		for i, val in ipairs @values
			if val == object
				return true

		return false

	includes: (...) => @has(...)
	contains: (...) => @has(...)

	remove: (object) =>
		return false if object == nil
		for i, val in ipairs @values
			if val == object
				table.remove(@values, i)
				return i

		return false

	delete: (...) => @remove(...)
	rm: (...) => @remove(...)
	unset: (...) => @remove(...)

	getValues: => @values
