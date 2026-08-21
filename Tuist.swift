import ProjectDescription

let tuist = Tuist(
    fullHandle: "forpda/forpda",
    project: .tuist(
        compatibleXcodeVersions: .list([.upToNextMajor("26.3"), .upToNextMajor("27.0")]),
        generationOptions: .options(
            optionalAuthentication: true
        ),
        cacheOptions: .options(
            storages: [.local]
        )
    )
)
