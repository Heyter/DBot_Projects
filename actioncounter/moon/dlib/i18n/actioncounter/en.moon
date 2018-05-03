
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

NetworkedValues = {
	{'jump', 'Jump streak: %s'}
	{'speed', 'Run distance: %sm'}
	{'duck', 'Duck distance: %sm'}
	{'walk', 'Walk distance: %sm'}
	{'water', 'On water distance: %sm'}
	{'uwater', 'Underwater distance: %sm'}
	{'fall', 'Fall distance: %sm'}
	{'climb', 'Climb distance: %sm'}
	{'height', 'Maximal potential height: %sm'}
}

for value in *NetworkedValues
	gui.actioncounter[value[1]] = value[2]
