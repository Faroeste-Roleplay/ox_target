/** @type {import('tailwindcss').Config} */
module.exports = {
	content: ["./src/**/*.{html,js,ts,tsx,jsx}"],
	theme: {
		extend: {
			fontFamily: {
				speedometer: "Speedometer",
				['aoboshi-one']: "Aoboshi One",
				anton: "Anton",
			},
			transitionProperty: {
				width: "width",
				height: "height",
			},
			colors: {
				dark: "#1D1E20",
				green: "#7EFBA2",
				darkGreen: "#001606",
				white: "#EEEEEE",
				red: "#FF3333",
				purple: "#F68DFF",
				darkPurple: "#19001C",
				orange: "#FFA483",
				darkOrange: "#1C0700",
				blue: "#858AFF",
				darkBlue: "#000120",
				blue2: "#6D72C3",
				yellow: "#FFF083",
				darkYellow: "#181500",
			},
		},
	},
	plugins: [],
};
