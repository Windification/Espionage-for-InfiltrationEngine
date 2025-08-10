local module = {
	Create = require(script._ActorCreation._Create),

	State = require(script._ActorState._State),
	Derived = require(script._ActorState._Derived),
	DerivedTable = require(script._ActorState._DerivedTable),
	Watch = require(script._ActorState._Watch),

	Spring = require(script._ActorAnim._ActorSpring),
	Cubic = require(script._ActorAnim._Cubic),

	OnChange = require(script._OnChange),
}

return module