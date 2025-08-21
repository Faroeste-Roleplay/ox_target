export interface ICoords {
    x: number;
    y: number;
    z: number;
}

export interface IScreenPosition {
    x: number;
    y: number;
}

export interface IZone {
    coords?: ICoords;
    screen?: IScreenPosition;
    options: Array<IOption[]>;
}


export interface IOptions {
    globalTarget: IOptionComplete[];
    __global: IOptionComplete[];
    model: IOptionComplete[];
};

export interface IOption {
    distance: number;
    label: string;
    name: string;
    resource?: string;
    event?: string;
    onSelect?: any;
    hide?: boolean;
}

export interface IOptionComplete extends IOption {
    coords: ICoords;
    screen: IScreenPosition;
}



// options
// [
// 	{
// 		"coords":{"x":-236.09226989746097,"y":787.397216796875,"z":118.87305450439452},
// 		"distance":2,
// 		"event":"CAMPFIRE:Client:Harvest",
// 		"label":"Pegar Gravetos",
// 		"name":"CAMPFIRE-Harvest",
// 		"resource":"ox_target"
// 	}	
// ]

// zones
// {
//     "options": [
//         [
//             {
//                 "distance": 2,
//                 "label": "Open Police Evidence",
//                 "onSelect": {
//                     "__cfx_functionReference": "ox_inventory:19878:15"
//                 },
//                 "name": "open_police_evidence"
//             }
//         ]
//     ],
//     "coords": {
//         "x": -278.2351989746094,
//         "y": 803.58251953125,
//         "z": 119.5999984741211
//     }
// }