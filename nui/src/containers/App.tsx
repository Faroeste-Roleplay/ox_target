import React, { useEffect } from "react";
import { debugData } from "../utils/debugData";
import { fetchNui } from "../hooks/fetchNui";
import { Options } from "../components/Options";


const App: React.FC = () => {

	// useEffect(() => {
	// 	fetchNui("useUIRoute",{ route: "IsReady", data: { } } );
	// }, [])

	return (
		<div className="flex w-screen h-screen justify-center items-center">
			<Options />
		</div>
	);
};

export default App;
