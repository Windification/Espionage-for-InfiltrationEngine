local module = {
	Create = require(script.Parent._ActorCreation._Create),

	State = require(script.Parent._ActorState._State),
	Derived = require(script.Parent._ActorState._Derived),
	DerivedTable = require(script.Parent._ActorState._DerivedTable),
	Watch = require(script.Parent._ActorState._Watch),

	Spring = require(script.Parent._ActorAnim._ActorSpring),
	Cubic = require(script.Parent._ActorAnim._Cubic),

	OnChange = require(script.Parent._OnChange),
}

return module