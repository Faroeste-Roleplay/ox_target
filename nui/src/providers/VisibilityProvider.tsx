import React, {
	Context,
	createContext,
	useContext,
	useEffect,
	useState,
} from "react";
import { useNuiEvent } from "../hooks/useNuiEvent";
import { fetchNui } from "../hooks/fetchNui";
import { IOption, IOptionComplete, IOptions, IScreenPosition, IZone } from "../types/types.d";
import { isEnvBrowser } from "../utils/misc";

const VisibilityCtx = createContext<VisibilityProviderValue | null>(null);

type DataProps = {
	zones?: IZone | undefined;
	options?: IOptions;
}


interface VisibilityProviderValue {
	setVisible: (visible: boolean) => void;
	setTargetData: (data: IOption[]) => void;
	targetData: IOption[];
	currentSelected: number;
	screenPosition: IScreenPosition;
	size: {
		width: number;
		height: number;
	}
	visible: boolean;
}

// This should be mounted at the top level of your application, it is currently set to
// apply a CSS visibility value. If this is non-performant, this should be customized.
export const VisibilityProvider: React.FC<{ children: React.ReactNode }> = ({
	children,
}) => {
	const [ screenPosition, setScreenPosition ] = useState<IScreenPosition>({ x: 0.49, y: 0.49})

	const [ targetData, setTargetData ] = useState<IOption[]>( isEnvBrowser() ? [
		{
			distance:0,
			label: "Algemar",
			name: "dk",
			// coords: { x: 0.5, y: 0.5, z: 0.1},
			// screen: { x: 0.5, y: 0.5},
		},
		{
			distance:0,
			label: "Carregar",
			name: "dk",
			// coords: { x: 0.5, y: 0.5, z: 0.1},
			// screen: { x: 0.5, y: 0.5},
		},
		{
			distance:0,
			label: "Soltar",
			name: "dk",
			// coords: { x: 0.5, y: 0.5, z: 0.1},
			// screen: { x: 0.5, y: 0.5},
		},
	] : [] )
	const [ visible, setVisible  ] = useState( isEnvBrowser() ? true : false);

	const [ currentSelected, setCurrentSelected  ] = useState<number>(0);

	useNuiEvent<boolean>("visible", setVisible);
	// useNuiEvent<IScreenPosition>("setScreenPosition", setScreenPosition);
	useNuiEvent<IOptionComplete[]>("setTarget", setTargetData);
	useNuiEvent<number>("setCurrentSelected", setCurrentSelected);

	
	useNuiEvent<DataProps>("leftTarget", () => setTargetData([]));

	const [size, setSize] = useState({
        width: window.innerWidth,
        height: window.innerHeight
    });

	useEffect(() => {
        const handleResize = () => {
        setSize({
            width: window.innerWidth,
            height: window.innerHeight
        });
        };

        window.addEventListener("resize", handleResize);
        return () => window.removeEventListener("resize", handleResize);
    }, []);


	// Handle pressing escape/backspace
	useEffect(() => {
		// Only attach listener when we are visible
		if (!isEnvBrowser()) return;

		const keyHandler = (e: KeyboardEvent) => {

			if (["ArrowDown"].includes(e.code)) {
				setCurrentSelected( prev => {
					const newValue = prev + 1

					if ( newValue >= targetData.length - 1 ) return targetData.length - 1

					return newValue
				} )
			}
			if (["ArrowUp"].includes(e.code)) {
				setCurrentSelected( prev => {
					const newValue = prev - 1

					if ( newValue < 0 ) return 0

					return newValue
				} )
			}
		};

		window.addEventListener("keydown", keyHandler);

		return () => window.removeEventListener("keydown", keyHandler);
	}, [visible]);


	return (
		<VisibilityCtx.Provider
			value={{
				visible,
				targetData,
				size,
				currentSelected,
				screenPosition,
				setVisible,
				setTargetData
			}}
		>
			<div
				style={{
					visibility: visible ? "visible" : "hidden",
					// visibility: "visible",
					height: "100%",
				}}
			>
				{children}
			</div>
		</VisibilityCtx.Provider>
	);
};

export const useVisibility = () =>
	useContext<VisibilityProviderValue>(
		VisibilityCtx as Context<VisibilityProviderValue>,
	);
