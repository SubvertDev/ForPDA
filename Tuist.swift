import ProjectDescription

let tuist = Tuist(
    fullHandle: "forpda/forpda",
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("26.3"),
        generationOptions: .options(
            optionalAuthentication: true
        ),
        cacheOptions: .options(
            storages: [.local]
        )
    )
)
