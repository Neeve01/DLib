
// Copyright (C) 2017-2019 DBotThePony

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import fs = require('fs')

const mkdir = (path: string) => {
	try {
		fs.statSync(path)
	} catch(err) {
		try {
			fs.mkdirSync(path)
		} catch(err2) {
			console.error(err2)
			console.error('Unable to access documentation output folder!')
			process.exit(1)
		}
	}
}

export {mkdir}
