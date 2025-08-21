import { useEffect, useRef, useState } from "react";
import { useVisibility } from "../providers/VisibilityProvider"
import { ItemOption } from "./ItemOption"
import { Separator } from "./ui/separator";
import { useNuiEvent } from "../hooks/useNuiEvent";
import { fetchNui } from "../hooks/fetchNui";


export const Options = () => {
    const { targetData, size, screenPosition, currentSelected } = useVisibility();
    const [ isPressed, setIsPressed ] = useState( false )

    useEffect(() => {
        if ( isPressed ) {
            setTimeout(() => {
                setIsPressed ( false )
                fetchNui("useUIRoute",{ route: "canPressAgain", data: { } } );
            }, 1000)
        }
    }, [isPressed])

    useNuiEvent("pressed", () => {
        setIsPressed( true )
    });

    return (
        <div
            className="relative w-full h-full flex flex-row justify-center items-center"
        >
            <div className="point" />
            {
                targetData && targetData.length >= 1 && 
                <div
                    className="absolute flex flex-row gap-1 items-start justify-start"
                    style ={{
                        top: screenPosition && screenPosition.y * size.height,
                        left: screenPosition && screenPosition.x * size.width,
                    }}
                >
                    <span
                        className={`lino text-black flex justify-center items-center h-[28px] w-[28px] bg-action ${isPressed && "pulse" }`}
                    >
                        E
                    </span>

                    <Separator orientation={"vertical"} />

                    <div
                        className="flex w-auto flex-col gap-1 relative justify-start items-start"
                        style={{
                            marginTop: screenPosition && screenPosition.y * ( -(currentSelected * 52) ),
                        }}
                    >
                        { 
                            targetData.map( (item, index) =>  
                                <ItemOption
                                    item={item}
                                    index={index}
                                />
                            )
                        }
                        
                    </div>
                </div>
            }
            
        </div>
    )
}