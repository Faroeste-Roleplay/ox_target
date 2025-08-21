import { useVisibility } from "../providers/VisibilityProvider"
import { IOption, IScreenPosition } from "../types/types.d"


export const ItemOption = ( {
   item,
   index,
}: { item : IOption; index: number}) => {
    const { currentSelected, size, screenPosition } = useVisibility()
    

    return (
        <div
            className={`max-h-[28px] px-[10px] bg-[#2d2d2d] lino ${currentSelected == index ? "item-hover" : "item"}`}
        >
           { item.label }
        </div>
    )
}