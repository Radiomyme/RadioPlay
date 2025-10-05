//
//  MockStationsService.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Data/Network/MockStationsService.swift
import Foundation

class MockStationsService {
    func getStations() -> [Station] {
        return [
            Station(
                id: "1",
                name: "RTL",
                subtitle: "RTL bouge",
                streamURL: "https://streaming.radio.rtl.fr/rtl-1-44-96",
                imageURL: "https://cdn-media.rtl.fr/cache/LlH3G2yGy3FcB8JSqtN02g/1800x1200-0/online/image/rtl.jpg",
                logoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/RTL_logo.svg/1200px-RTL_logo.svg.png"
            ),
            Station(
                id: "2",
                name: "Europe 1",
                subtitle: "Europe 1, Mieux capter son époque",
                streamURL: "https://stream.europe1.fr/europe1.mp3",
                imageURL: "https://cdn-europe1.lanmedia.fr/var/europe1/storage/images/europe1/medias-tele/europe-1-premiere-radio-a-proposer-son-application-sur-apple-watch-2430085/24085526-1-fre-FR/Europe-1-premiere-radio-a-proposer-son-application-sur-Apple-Watch.jpg",
                logoURL: "https://upload.wikimedia.org/wikipedia/commons/e/e8/Europe_1_logo_%282010%29.svg"
            ),
            Station(
                id: "3",
                name: "NRJ",
                subtitle: "Hit Music Only",
                streamURL: "https://scdn.nrjaudio.fm/audio1/fr/30001/mp3_128.mp3",
                imageURL: "https://cdn.nrjaudio.fm/adimg/6779/3535779/1900x1080_NRJ-Supernova_1.jpg",
                logoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/NRJ_logo_2019.svg/1200px-NRJ_logo_2019.svg.png"
            ),
            Station(
                id: "4",
                name: "France INFO",
                subtitle: "Actualités en temps réel et info en direct",
                streamURL: "https://icecast.radiofrance.fr/franceinfo-midfi.mp3",
                imageURL: "https://cdn-media.rtl.fr/online/image/2015/0623/7778732219_franceinfo-logo.jpg",
                logoURL: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/03/Franceinfo.svg/1200px-Franceinfo.svg.png"
            )
        ]
    }
}
