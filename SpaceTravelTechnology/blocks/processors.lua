-- Electric furnace
spacetraveltechnology.register_processing_machine(
	"spacetraveltechnology:electric_furnace",
	"Electric Furnace",
	{
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^electric_furnace_front.png"
	},
	{
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^electric_furnace_front_active.png"
	},
	{spacetravelcore.recipe_types.cooking},
	5
);

-- Macerator
spacetraveltechnology.register_processing_machine(
	"spacetraveltechnology:macerator",
	"Macerator",
	{
		"machine.png^macerator_top.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^macerator_front.png"
	},
	{
		"machine.png^macerator_top_active.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^machine_output.png",
		"machine.png^macerator_front.png"
	},
	{spacetravelcore.recipe_types.grinding},
	5
);
