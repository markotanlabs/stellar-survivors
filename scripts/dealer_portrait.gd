extends Control
## The Arms Dealer: a scrap goblin squatting on a pile of wrecked ship parts, flipping
## a coin, with a nav light blinking green on the antenna beside him. Shown on the
## left of the shop screen. Pixel art like Xander (v0.9.159): the shapes are drawn at
## a third of their size into a small viewport with no smoothing, then blown back up
## with nearest filtering, so every pixel is a chunky 3x3 block.
## Designed on a 420x560 box; the control scales it to whatever size it's given.

const DESIGN := Vector2(420, 560)
const NECK := Vector2(218, 240)
const SHOULDER_R := Vector2(246, 264)
const ELBOW_R := Vector2(282, 302)
const PIX := 3.0   # design units per art pixel
# Spots on the scrap pile that catch the light now and then: [position, period s, offset s].
const GLINTS := [
	[Vector2(88, 519), 3.1, 0.2], [Vector2(142, 492), 4.3, 1.9], [Vector2(146, 462), 3.7, 0.9],
	[Vector2(348, 404), 3.4, 2.6], [Vector2(132, 448), 4.9, 3.3], [Vector2(222, 508), 3.9, 1.3],
	[Vector2(392, 490), 4.6, 0.5], [Vector2(108, 392), 5.2, 2.2], [Vector2(288, 460), 3.3, 2.9],
	[Vector2(176, 424), 4.1, 3.8],
]
const CANOPY := [Vector2(196, 392), Vector2(262, 378), Vector2(290, 412), Vector2(226, 428)]
const OUTLINE := [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(-0.7, -0.7), Vector2(0.7, -0.7), Vector2(-0.7, 0.7), Vector2(0.7, 0.7)]

const COL := {
	"ol": Color("0b0e14"),
	"pile": Color("232a36"),
	"pile_d": Color("191e28"),
	"steel": Color("56627a"),
	"steel_l": Color("7a879c"),
	"steel_d": Color("3a4354"),
	"plate2": Color("4a5568"),
	"rivet": Color("9aa6b8"),
	"rust": Color("8a4a2a"),
	"rust_l": Color("b0643a"),
	"gold": Color("e8c14a"),
	"orange": Color("e07a2e"),
	"glass": Color("2f8fa3"),
	"glass_l": Color("8fe3f0"),
	"wire_r": Color("c0392b"),
	"wire_b": Color("3e6690"),
	"wire_y": Color("d9b23a"),
	"crate": Color("6b4a2e"),
	"crate_d": Color("4a321f"),
	"red": Color("a4504a"),
	"st": Color("7d87a9"), "st_l": Color("a7b1cf"), "st_d": Color("59617f"), "st_dd": Color("3d4462"),
	"gold_l": Color("f6dc80"),
	"cloth": Color("a08a5a"), "cloth_d": Color("7a6842"), "cloth_l": Color("c2ab78"),
	"teal": Color("5fcfbf"),
	"sk": Color("7fae4a"),
	"sk_l": Color("a3cf63"),
	"sk_d": Color("557a2f"),
	"sk_dd": Color("3c5a20"),
	"vest": Color("5a3f2a"),
	"vest_d": Color("3f2b1c"),
	"vest_l": Color("7a573a"),
	"eye": Color("f2e05a"),
	"eye_glow": Color("f2e05a"),
	"tooth": Color("efe8d0"),
	"mouth": Color("2a1416"),
	"gog": Color("5fd6e8"),
	"gog_d": Color("2a6f7a"),
	"strap": Color("2a2540"),
	"nail": Color("d8d2b8"),
	"patch": Color("3e6690"),
}
const PILE := [
	["poly", "pile", [Vector2(4, 560), Vector2(18, 488), Vector2(52, 436), Vector2(98, 396), Vector2(150, 364), Vector2(210, 348), Vector2(272, 354), Vector2(326, 384), Vector2(372, 428), Vector2(404, 480), Vector2(418, 560)]],
	["line", "steel_d", [Vector2(340, 400), Vector2(372, 300)], 6.0],
	["poly", "steel_d", [Vector2(352, 318), Vector2(396, 300), Vector2(392, 316)]],
	["poly", "steel_d", [Vector2(300, 420), Vector2(360, 396), Vector2(392, 470), Vector2(330, 492)]],
	["poly", "ol", [Vector2(384.0, 444.0), Vector2(382.7, 457.7), Vector2(378.9, 469.7), Vector2(373.0, 478.6), Vector2(365.8, 483.4), Vector2(358.2, 483.4), Vector2(351.0, 478.6), Vector2(345.1, 469.7), Vector2(341.3, 457.7), Vector2(340.0, 444.0), Vector2(341.3, 430.3), Vector2(345.1, 418.3), Vector2(351.0, 409.4), Vector2(358.2, 404.6), Vector2(365.8, 404.6), Vector2(373.0, 409.4), Vector2(378.9, 418.3), Vector2(382.7, 430.3)]],
	["poly", "rust", [Vector2(379.0, 444.0), Vector2(378.0, 455.3), Vector2(375.0, 465.2), Vector2(370.5, 472.6), Vector2(365.0, 476.5), Vector2(359.0, 476.5), Vector2(353.5, 472.6), Vector2(349.0, 465.2), Vector2(346.0, 455.3), Vector2(345.0, 444.0), Vector2(346.0, 432.7), Vector2(349.0, 422.8), Vector2(353.5, 415.4), Vector2(359.0, 411.5), Vector2(365.0, 411.5), Vector2(370.5, 415.4), Vector2(375.0, 422.8), Vector2(378.0, 432.7)]],
	["poly", "orange", [Vector2(373.0, 444.0), Vector2(372.1, 452.7), Vector2(369.6, 459.6), Vector2(366.0, 463.5), Vector2(362.0, 463.5), Vector2(358.4, 459.6), Vector2(355.9, 452.7), Vector2(355.0, 444.0), Vector2(355.9, 435.3), Vector2(358.4, 428.4), Vector2(362.0, 424.5), Vector2(366.0, 424.5), Vector2(369.6, 428.4), Vector2(372.1, 435.3)]],
	["poly", "glass", [Vector2(196, 392), Vector2(262, 378), Vector2(290, 412), Vector2(226, 428)]],
	["poly", "glass_l", [Vector2(214, 394), Vector2(256, 386), Vector2(262, 392), Vector2(220, 400)]],
	["line", "ol", [Vector2(240, 384), Vector2(250, 404)], 2.0],
	["line", "ol", [Vector2(250, 404), Vector2(238, 420)], 2.0],
	["line", "ol", [Vector2(250, 404), Vector2(272, 410)], 2.0],
	["line", "ol", [Vector2(70, 470), Vector2(196, 420)], 18.0],
	["line", "steel_l", [Vector2(70, 470), Vector2(196, 420)], 12.0],
	["line", "steel", [Vector2(72, 474), Vector2(196, 426)], 4.0],
	["circle", "ol", Vector2(198, 421), 10.0],
	["circle", "steel_d", Vector2(198, 421), 6.0],
	["poly", "ol", [Vector2(152.0, 486.0), Vector2(159.5, 492.6), Vector2(157.9, 499.0), Vector2(148.3, 501.4), Vector2(145.5, 506.0), Vector2(147.7, 515.7), Vector2(142.7, 520.0), Vector2(133.4, 516.3), Vector2(128.5, 518.3), Vector2(124.6, 527.5), Vector2(118.0, 528.0), Vector2(112.7, 519.6), Vector2(107.5, 518.3), Vector2(98.9, 523.4), Vector2(93.3, 520.0), Vector2(94.0, 510.0), Vector2(90.5, 506.0), Vector2(80.6, 505.1), Vector2(78.1, 499.0), Vector2(84.4, 491.3), Vector2(84.0, 486.0), Vector2(76.5, 479.4), Vector2(78.1, 473.0), Vector2(87.7, 470.6), Vector2(90.5, 466.0), Vector2(88.3, 456.3), Vector2(93.3, 452.0), Vector2(102.6, 455.7), Vector2(107.5, 453.7), Vector2(111.4, 444.5), Vector2(118.0, 444.0), Vector2(123.3, 452.4), Vector2(128.5, 453.7), Vector2(137.1, 448.6), Vector2(142.7, 452.0), Vector2(142.0, 462.0), Vector2(145.5, 466.0), Vector2(155.4, 466.9), Vector2(157.9, 473.0), Vector2(151.6, 480.7)]],
	["poly", "steel", [Vector2(149.0, 486.0), Vector2(155.5, 491.9), Vector2(154.1, 497.7), Vector2(145.6, 500.1), Vector2(143.1, 504.2), Vector2(144.9, 512.9), Vector2(140.3, 516.7), Vector2(132.1, 513.6), Vector2(127.6, 515.5), Vector2(123.9, 523.5), Vector2(118.0, 524.0), Vector2(113.2, 516.6), Vector2(108.4, 515.5), Vector2(100.7, 519.9), Vector2(95.7, 516.7), Vector2(96.1, 507.9), Vector2(92.9, 504.2), Vector2(84.1, 503.3), Vector2(81.9, 497.7), Vector2(87.4, 490.8), Vector2(87.0, 486.0), Vector2(80.5, 480.1), Vector2(81.9, 474.3), Vector2(90.4, 471.9), Vector2(92.9, 467.8), Vector2(91.1, 459.1), Vector2(95.7, 455.3), Vector2(103.9, 458.4), Vector2(108.4, 456.5), Vector2(112.1, 448.5), Vector2(118.0, 448.0), Vector2(122.8, 455.4), Vector2(127.6, 456.5), Vector2(135.3, 452.1), Vector2(140.3, 455.3), Vector2(139.9, 464.1), Vector2(143.1, 467.8), Vector2(151.9, 468.7), Vector2(154.1, 474.3), Vector2(148.6, 481.2)]],
	["circle", "steel_d", Vector2(118, 486), 15.0],
	["circle", "pile_d", Vector2(118, 486), 8.0],
	["poly", "steel", [Vector2(18, 548), Vector2(146, 486), Vector2(178, 542), Vector2(52, 566)]],
	["poly", "steel_l", [Vector2(20, 544), Vector2(146, 486), Vector2(150, 494), Vector2(26, 550)]],
	["circle", "rivet", Vector2(52, 536), 3.0],
	["circle", "rivet", Vector2(88, 519), 3.0],
	["circle", "rivet", Vector2(124, 502), 3.0],
	["poly", "rust", [Vector2(120, 530), Vector2(150, 518), Vector2(160, 536), Vector2(128, 546)]],
	["poly", "gold", [Vector2(170, 516), Vector2(276, 494), Vector2(290, 548), Vector2(182, 566)]],
	["poly", "ol", [Vector2(184, 513), Vector2(200, 510), Vector2(214, 563), Vector2(198, 566)]],
	["poly", "ol", [Vector2(216, 507), Vector2(232, 504), Vector2(246, 557), Vector2(230, 560)]],
	["poly", "ol", [Vector2(248, 500), Vector2(264, 497), Vector2(278, 551), Vector2(262, 554)]],
	["poly", "crate", [Vector2(300, 500), Vector2(392, 488), Vector2(404, 560), Vector2(310, 566)]],
	["poly", "crate_d", [Vector2(300, 500), Vector2(392, 488), Vector2(394, 500), Vector2(302, 512)]],
	["line", "crate_d", [Vector2(305, 536), Vector2(398, 526)], 4.0],
	["line", "crate_d", [Vector2(350, 494), Vector2(356, 562)], 4.0],
	["polyline", "wire_r", [Vector2(150, 440), Vector2(176, 470), Vector2(206, 462), Vector2(232, 480), Vector2(262, 470)], 4.0],
	["polyline", "wire_b", [Vector2(130, 452), Vector2(168, 488), Vector2(210, 478), Vector2(250, 500)], 4.0],
	["polyline", "wire_y", [Vector2(280, 440), Vector2(300, 470), Vector2(286, 500)], 3.0],
	["circle", "rivet", Vector2(288, 460), 4.0],
	["circle", "rivet", Vector2(160, 470), 3.0],
	["circle", "rivet", Vector2(330, 470), 3.0]
]
const BODY := [
	["line", "vest_d", [Vector2(204, 342), Vector2(164, 366)], 22.0],
	["line", "vest_d", [Vector2(232, 342), Vector2(272, 366)], 22.0],
	["circle", "sk", Vector2(162, 368), 11.0],
	["circle", "sk", Vector2(274, 368), 11.0],
	["line", "sk", [Vector2(162, 368), Vector2(158, 414)], 15.0],
	["line", "sk", [Vector2(274, 368), Vector2(280, 414)], 15.0],
	["poly", "sk", [Vector2(140, 410), Vector2(168, 406), Vector2(174, 420), Vector2(134, 426)]],
	["poly", "sk", [Vector2(270, 406), Vector2(300, 410), Vector2(306, 426), Vector2(266, 422)]],
	["poly", "sk", [Vector2(186, 350), Vector2(180, 304), Vector2(188, 268), Vector2(204, 248), Vector2(232, 248), Vector2(248, 268), Vector2(256, 304), Vector2(250, 350)]]
]
const BODY_DETAIL := [
	["line", "sk_d", [Vector2(154, 376), Vector2(152, 404)], 4.0],
	["line", "sk_d", [Vector2(282, 376), Vector2(286, 404)], 4.0],
	["poly", "nail", [Vector2(135, 423), Vector2(130, 429), Vector2(141, 425)]],
	["poly", "nail", [Vector2(146, 422), Vector2(143, 429), Vector2(152, 423)]],
	["poly", "nail", [Vector2(305, 423), Vector2(310, 429), Vector2(299, 425)]],
	["poly", "nail", [Vector2(294, 422), Vector2(297, 429), Vector2(288, 423)]],
	["poly", "vest_d", [Vector2(170, 354), Vector2(162, 350), Vector2(156, 360), Vector2(150, 356), Vector2(160, 374), Vector2(178, 368)]],
	["poly", "vest_d", [Vector2(266, 354), Vector2(274, 350), Vector2(280, 360), Vector2(286, 356), Vector2(276, 374), Vector2(258, 368)]],
	["poly", "sk_l", [Vector2(206, 262), Vector2(230, 262), Vector2(236, 290), Vector2(218, 298), Vector2(200, 290)]],
	["poly", "sk_d", [Vector2(196, 330), Vector2(218, 340), Vector2(240, 330), Vector2(246, 346), Vector2(190, 346)]],
	["poly", "vest", [Vector2(184, 350), Vector2(178, 302), Vector2(186, 266), Vector2(204, 246), Vector2(212, 246), Vector2(204, 300), Vector2(202, 350)]],
	["poly", "vest", [Vector2(252, 350), Vector2(258, 302), Vector2(250, 266), Vector2(232, 246), Vector2(224, 246), Vector2(232, 300), Vector2(234, 350)]],
	["poly", "vest_l", [Vector2(186, 268), Vector2(204, 248), Vector2(208, 250), Vector2(192, 272)]],
	["poly", "vest_l", [Vector2(250, 268), Vector2(232, 248), Vector2(228, 250), Vector2(244, 272)]],
	["poly", "patch", [Vector2(186, 312), Vector2(198, 310), Vector2(199, 324), Vector2(187, 326)]],
	["line", "gold", [Vector2(188, 314), Vector2(197, 312)], 1.0],
	["line", "gold", [Vector2(188, 323), Vector2(197, 321)], 1.0],
	["circle", "gold", Vector2(240, 290), 2.5],
	["circle", "gold", Vector2(241, 312), 2.5],
	["poly", "strap", [Vector2(184, 336), Vector2(252, 336), Vector2(252, 346), Vector2(184, 346)]],
	["poly", "gold", [Vector2(210, 334), Vector2(226, 334), Vector2(226, 348), Vector2(210, 348)]],
	["poly", "strap", [Vector2(214, 338), Vector2(222, 338), Vector2(222, 344), Vector2(214, 344)]]
]
const ARM_L := [
	["line", "sk", [Vector2(192, 266), Vector2(160, 308)], 15.0],
	["line", "sk", [Vector2(160, 308), Vector2(164, 354)], 13.0],
	["circle", "sk", Vector2(160, 308), 7.5],
	["line", "steel", [Vector2(164, 358), Vector2(120, 396)], 7.0],
	["poly", "steel", [Vector2(108, 392), Vector2(126, 388), Vector2(130, 404), Vector2(120, 414), Vector2(116, 402), Vector2(108, 406)]],
	["circle", "sk", Vector2(165, 357), 10.0]
]
const ARM_L_DETAIL := [
	["line", "sk_d", [Vector2(163, 314), Vector2(164, 346)], 4.0],
	["line", "steel_l", [Vector2(164, 353), Vector2(126, 388)], 2.0]
]
const HEAD := [
	["poly", "sk", [Vector2(-30, -60), Vector2(-104, -96), Vector2(-92, -78), Vector2(-36, -40)]],
	["poly", "sk", [Vector2(30, -60), Vector2(104, -96), Vector2(92, -78), Vector2(36, -40)]],
	["poly", "sk", [Vector2(-34, -70), Vector2(-22, -88), Vector2(0, -94), Vector2(22, -88), Vector2(34, -70), Vector2(38, -46), Vector2(30, -24), Vector2(14, -10), Vector2(0, -8), Vector2(-14, -10), Vector2(-30, -24), Vector2(-38, -46)]],
	["poly", "sk", [Vector2(-12, -6), Vector2(12, -6), Vector2(14, 8), Vector2(-14, 8)]]
]
const HEAD_DETAIL := [
	["poly", "sk_d", [Vector2(-36, -58), Vector2(-92, -88), Vector2(-40, -46)]],
	["poly", "sk_d", [Vector2(36, -58), Vector2(92, -88), Vector2(40, -46)]],
	["poly", "sk_dd", [Vector2(-60, -74), Vector2(-86, -86), Vector2(-62, -70)]],
	["poly", "sk_l", [Vector2(-22, -86), Vector2(0, -92), Vector2(22, -86), Vector2(14, -82), Vector2(-14, -82)]],
	["poly", "sk_d", [Vector2(-30, -24), Vector2(-14, -10), Vector2(0, -8), Vector2(14, -10), Vector2(30, -24), Vector2(18, -18), Vector2(0, -14), Vector2(-18, -18)]],
	["poly", "sk_d", [Vector2(-12, 4), Vector2(12, 4), Vector2(14, 8), Vector2(-14, 8)]],
	["line", "strap", [Vector2(-35, -74), Vector2(35, -74)], 5.0],
	["circle", "ol", Vector2(-13, -76), 11.0],
	["circle", "ol", Vector2(13, -76), 11.0],
	["circle", "gog_d", Vector2(-13, -76), 8.5],
	["circle", "gog_d", Vector2(13, -76), 8.5],
	["circle", "gog", Vector2(-15, -78), 4.5],
	["circle", "gog", Vector2(11, -78), 4.5],
	["poly", "sk_dd", [Vector2(-30, -62), Vector2(-10, -56), Vector2(0, -60), Vector2(10, -56), Vector2(30, -62), Vector2(28, -55), Vector2(10, -50), Vector2(0, -54), Vector2(-10, -50), Vector2(-28, -55)]],
	["poly", "mouth", [Vector2(-22, -27), Vector2(-8, -20), Vector2(8, -20), Vector2(22, -27), Vector2(16, -17), Vector2(0, -13), Vector2(-16, -17)]],
	["poly", "tooth", [Vector2(-13, -17), Vector2(-10, -25), Vector2(-7, -17)]],
	["poly", "tooth", [Vector2(7, -17), Vector2(10, -25), Vector2(13, -17)]],
	["poly", "sk", [Vector2(-6, -56), Vector2(6, -56), Vector2(11, -38), Vector2(9, -25), Vector2(2, -18), Vector2(-3, -24), Vector2(-7, -38)]],
	["poly", "sk_l", [Vector2(-3, -54), Vector2(2, -54), Vector2(4, -40), Vector2(0, -36)]],
	["poly", "sk_d", [Vector2(2, -18), Vector2(9, -25), Vector2(5, -26)]],
	["circle", "sk_d", Vector2(-26, -40), 2.5],
	["circle", "sk_d", Vector2(24, -34), 2.0],
	["line", "sk_dd", [Vector2(20, -66), Vector2(28, -50)], 2.0],
	["circle", "gold", Vector2(64, -58), 6.0],
	["circle", "sk", Vector2(64, -58), 3.5]
]

# The rest of the Thinker from the intro: the headless statue under a tarp and a chain
# (left of the pile) and his X-eyed head on the floor (v0.9.170).
const BUST := [
	["poly", "st", [Vector2(14, 422.0), Vector2(12, 338.8), Vector2(22, 281.6), Vector2(44, 247.8), Vector2(72, 237.39999999999998), Vector2(94, 247.8), Vector2(104, 276.4), Vector2(102, 331.0), Vector2(92, 385.6), Vector2(88, 422.0)]],
	["poly", "st", [Vector2(92, 268.6), Vector2(108, 263.4), Vector2(116, 318.0), Vector2(104, 323.2)]],
	["poly", "st", [Vector2(96, 245.2), Vector2(110, 234.8), Vector2(118, 245.2), Vector2(106, 258.2)]]
]
const BUST_DETAIL := [
	["poly", "st_l", [Vector2(24, 281.6), Vector2(44, 250.39999999999998), Vector2(72, 240.0), Vector2(90, 247.8), Vector2(72, 250.39999999999998), Vector2(46, 260.8), Vector2(28, 294.6)]],
	["poly", "st_d", [Vector2(14, 422.0), Vector2(12, 359.6), Vector2(22, 364.8), Vector2(28, 422.0)]],
	["poly", "st_l", [Vector2(81.0, 240.0), Vector2(79.9, 242.2), Vector2(76.9, 244.0), Vector2(72.4, 245.10000000000002), Vector2(67.6, 245.10000000000002), Vector2(63.099999999999994, 244.0), Vector2(60.099999999999994, 242.2), Vector2(59.0, 240.0), Vector2(60.099999999999994, 237.8), Vector2(63.099999999999994, 236.0), Vector2(67.6, 234.89999999999998), Vector2(72.4, 234.89999999999998), Vector2(76.9, 236.0), Vector2(79.9, 237.8)]],
	["poly", "st_d", [Vector2(77.0, 241.3), Vector2(76.1, 242.89999999999998), Vector2(73.5, 244.0), Vector2(70.0, 244.39999999999998), Vector2(66.5, 244.0), Vector2(63.900000000000006, 242.89999999999998), Vector2(63.0, 241.3), Vector2(63.900000000000006, 239.7), Vector2(66.5, 238.60000000000002), Vector2(70.0, 238.2), Vector2(73.5, 238.60000000000002), Vector2(76.1, 239.7)]],
	["line", "st_dd", [Vector2(52, 281.6), Vector2(62, 310.2)], 2.0],
	["line", "st_dd", [Vector2(62, 310.2), Vector2(56, 333.6)], 2.0],
	["poly", "cloth", [Vector2(18, 297.2), Vector2(38, 266.0), Vector2(62, 255.60000000000002), Vector2(82, 263.4), Vector2(76, 294.6), Vector2(86, 357.0), Vector2(72, 349.2), Vector2(64, 377.8), Vector2(52, 354.4), Vector2(40, 383.0), Vector2(32, 349.2), Vector2(20, 364.8)]],
	["poly", "cloth_l", [Vector2(38, 266.0), Vector2(62, 255.60000000000002), Vector2(80, 263.4), Vector2(62, 266.0), Vector2(44, 276.4)]],
	["line", "cloth_d", [Vector2(50, 276.4), Vector2(44, 364.8)], 3.0],
	["line", "cloth_d", [Vector2(68, 271.2), Vector2(70, 354.4)], 3.0],
	["poly", "cloth_d", [Vector2(76, 294.6), Vector2(86, 357.0), Vector2(78, 349.2)]]
]
const CHAIN := [Vector2(104, 253.0), Vector2(108, 271.2), Vector2(110, 289.4), Vector2(110, 307.6), Vector2(108, 325.8), Vector2(102, 344.0), Vector2(94, 359.6), Vector2(84, 372.6)]
const STONE_HEAD := [
	["poly", "st", [Vector2(382.6, 520.2), Vector2(378.8, 530.9), Vector2(373.0, 540.3), Vector2(365.2, 547.8), Vector2(356.0, 552.8), Vector2(346.3, 555.1), Vector2(336.5, 554.4), Vector2(327.2, 550.8), Vector2(319.5, 544.7), Vector2(313.5, 536.2), Vector2(309.5, 526.1), Vector2(308.2, 515.2), Vector2(309.4, 503.8), Vector2(313.2, 493.1), Vector2(319.0, 483.7), Vector2(326.8, 476.2), Vector2(336.0, 471.2), Vector2(345.7, 469.0), Vector2(355.5, 469.5), Vector2(364.8, 473.2), Vector2(372.5, 479.3), Vector2(378.5, 487.8), Vector2(382.5, 497.9), Vector2(383.8, 508.8)]],
	["poly", "st", [Vector2(311.3, 495.0), Vector2(302.3, 480.7), Vector2(297.8, 507.3), Vector2(308.2, 515.9)]],
	["poly", "st", [Vector2(384.5, 511.4), Vector2(399.0, 502.2), Vector2(391.6, 528.3), Vector2(378.5, 531.5)]]
]
const STONE_HEAD_DETAIL := [
	["poly", "st_l", [Vector2(326.2, 476.9), Vector2(346.5, 469.1), Vector2(366.8, 473.6), Vector2(378.8, 488.6), Vector2(362.3, 480.3), Vector2(341.8, 475.7)]],
	["poly", "st_d", [Vector2(311.2, 516.5), Vector2(318.2, 539.6), Vector2(336.5, 554.4), Vector2(359.3, 548.8), Vector2(375.5, 530.9), Vector2(357.7, 542.3), Vector2(338.8, 544.2), Vector2(322.6, 534.3)]],
	["poly", "st_dd", [Vector2(320.7, 487.8), Vector2(343.2, 497.5), Vector2(354.8, 500.2), Vector2(379.2, 501.0), Vector2(376.5, 506.5), Vector2(353.5, 506.0), Vector2(341.8, 503.3), Vector2(320.8, 494.0)]],
	["line", "ol", [Vector2(325.8, 499.7), Vector2(336.2, 514.4)], 3.9000000000000004],
	["line", "ol", [Vector2(338.8, 502.7), Vector2(323.0, 511.5)], 3.9000000000000004],
	["line", "ol", [Vector2(356.3, 506.6), Vector2(367.0, 521.3)], 3.9000000000000004],
	["line", "ol", [Vector2(369.5, 509.6), Vector2(353.8, 518.3)], 3.9000000000000004],
	["poly", "st_d", [Vector2(342.2, 508.1), Vector2(351.1, 510.0), Vector2(350.0, 528.3), Vector2(335.3, 525.1)]],
	["line", "st_dd", [Vector2(327.2, 533.9), Vector2(354.0, 538.4)], 3.9000000000000004],
	["line", "st_dd", [Vector2(369.8, 474.3), Vector2(371.8, 493.1)], 2.6],
	["line", "st_dd", [Vector2(371.8, 493.1), Vector2(382.2, 501.7)], 2.6]
]
# His plinth with the snapped-off gold plaque, and scrap round its foot (v0.9.171).
const PLINTH := [
	["poly", "st_d", [Vector2(10, 420), Vector2(112, 416), Vector2(118, 474), Vector2(6, 478)]]
]
const PLINTH_DETAIL := [
	["poly", "st_l", [Vector2(10, 420), Vector2(112, 416), Vector2(112, 422), Vector2(12, 426)]],
	["poly", "st_dd", [Vector2(100, 422), Vector2(112, 422), Vector2(118, 474), Vector2(104, 476)]],
	["poly", "ol", [Vector2(16, 426), Vector2(92, 423), Vector2(87, 432), Vector2(95, 441), Vector2(88, 450), Vector2(94, 459), Vector2(87, 468), Vector2(14, 471)]],
	["poly", "gold", [Vector2(19, 429), Vector2(89, 426), Vector2(84, 432), Vector2(91, 441), Vector2(84, 450), Vector2(90, 459), Vector2(84, 465), Vector2(17, 468)]],
	["poly", "gold_l", [Vector2(19, 429), Vector2(89, 426), Vector2(87, 430), Vector2(21, 433)]]
]
const SCRAP_FOOT := [
	["poly", "rust", [Vector2(-4, 478), Vector2(30, 474), Vector2(36, 516), Vector2(-2, 522)]],
	["poly", "rust_l", [Vector2(-4, 478), Vector2(30, 474), Vector2(31, 481), Vector2(-3, 486)]],
	["line", "ol", [Vector2(0, 498), Vector2(34, 494)], 3.0],
	["poly", "plate2", [Vector2(30, 476), Vector2(96, 470), Vector2(100, 500), Vector2(26, 506)]],
	["poly", "steel_l", [Vector2(30, 476), Vector2(96, 470), Vector2(97, 475), Vector2(31, 481)]],
	["circle", "rivet", Vector2(40, 488), 2.5],
	["circle", "rivet", Vector2(88, 484), 2.5]
]
const PLAQUE_TEXT := "MAR"
const PLAQUE_AT := Vector2(23, 461)
const PLAQUE_SIZE := 32

var _view: SubViewport
var _art: Art


func _init() -> void:
	custom_minimum_size = DESIGN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps moving while the shop pauses the game
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_view = SubViewport.new()
	_view.size = Vector2i(int(DESIGN.x / PIX), int(DESIGN.y / PIX))
	_view.transparent_bg = true
	_view.msaa_2d = Viewport.MSAA_DISABLED
	_view.snap_2d_vertices_to_pixel = true
	_view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_view)
	_art = Art.new()
	_view.add_child(_art)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var k := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	var box := DESIGN * k
	draw_texture_rect(_view.get_texture(), Rect2((size - box) / 2.0, box), false)


## Draws the dealer in design units, shrunk by PIX into the little viewport.
class Art extends Node2D:
	var _t := 0.0
	var _stack: Array = [Transform2D.IDENTITY]

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()




	func _push(pos: Vector2, rot: float = 0.0, sx: float = 1.0, sy: float = 1.0) -> void:
		var m: Transform2D = _stack[-1] * Transform2D(rot, Vector2(sx, sy), 0.0, pos)
		_stack.append(m)
		draw_set_transform_matrix(m)


	func _pop() -> void:
		_stack.pop_back()
		draw_set_transform_matrix(_stack[-1])


	## Draws a list of shapes, all in one colour if `over` is given (for the outline pass).
	## `grow` thickens lines and circles (the outline pass uses it too).
	func _shapes(list: Array, over: Variant = null, grow: float = 0.0) -> void:
		for s in list:
			var col: Color = COL[String(s[1])] if over == null else over
			match String(s[0]):
				"poly":
					draw_colored_polygon(PackedVector2Array(s[2]), col)
				"circle":
					draw_circle(s[2], float(s[3]) + grow, col)
				"line":
					draw_line(s[2][0], s[2][1], col, float(s[3]) + grow * 2.0)
				"polyline":
					var pts: Array = s[2]
					for i in pts.size() - 1:
						draw_line(pts[i], pts[i + 1], col, float(s[3]) + grow * 2.0)
					for i in range(1, pts.size() - 1):
						draw_circle(pts[i], (float(s[3]) + grow * 2.0) / 2.0, col)


	## A group with a dark outline all round it (drawn nudged out eight ways first).
	## Little four-point twinkles popping on the metal, each on its own beat.
	func _glints(t: float) -> void:
		for g in GLINTS:
			var k := fmod(t + float(g[2]), float(g[1])) / 0.4
			if k >= 1.0:
				continue
			var p: Vector2 = g[0]
			var s := sin(k * PI)
			var c := Color(1.0, 0.98, 0.86, s)
			draw_line(p - Vector2(10.0 * s, 0), p + Vector2(10.0 * s, 0), c, PIX)
			draw_line(p - Vector2(0, 10.0 * s), p + Vector2(0, 10.0 * s), c, PIX)
			draw_circle(p, PIX * (0.6 + s), Color(1, 1, 1, s))

	## A sheen sliding across the cracked canopy glass every few seconds.
	func _gleam_canopy(t: float) -> void:
		var u := fmod(t, 4.2) / 0.7
		if u >= 1.0:
			return
		var a: Vector2 = (CANOPY[0] as Vector2).lerp(CANOPY[1], u)
		var b: Vector2 = (CANOPY[3] as Vector2).lerp(CANOPY[2], u)
		draw_line(a + (b - a) * 0.1, b - (b - a) * 0.1, Color(0.9, 1.0, 1.0, 0.75 * sin(u * PI)), PIX * 1.6)

	func _outlined(list: Array, width: float = PIX) -> void:
		for o in OUTLINE:
			_push(Vector2(o) * width)
			_shapes(list, COL["ol"])
			_pop()
		_shapes(list)


	func _draw() -> void:
		_stack = [Transform2D.IDENTITY]
		_push(Vector2.ZERO, 0.0, 1.0 / PIX, 1.0 / PIX)
		var t := _t
		# The headless statue, tarp and chain, half buried at the back left.
		_outlined(BUST)
		_shapes(BUST_DETAIL)
		for i in CHAIN.size():
			var link: Vector2 = CHAIN[i]
			draw_circle(link, 5.5, COL["ol"])
			draw_circle(link, 4.0, COL["steel_l"] if i % 2 == 0 else COL["steel"])
			draw_circle(link, 1.8, COL["ol"])
		# The scrap pile, the plinth with its broken plaque, the rest of the scrap.
		_outlined([PILE[0]])
		_outlined(PLINTH)
		_shapes(PLINTH_DETAIL)
		draw_string(ThemeDB.fallback_font, PLAQUE_AT, PLAQUE_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, PLAQUE_SIZE, COL["ol"])
		_shapes(PILE.slice(1))
		_outlined([SCRAP_FOOT[0]])
		_shapes(SCRAP_FOOT)
		# His stone head on the floor, X'd out, facing you.
		draw_circle(Vector2(346, 560), 44.0, Color(0, 0, 0, 0.35))
		_outlined(STONE_HEAD)
		_shapes(STONE_HEAD_DETAIL)
		# The nav light on the antenna mast: a short green blink every 1.4 s.
		var lit := fmod(t, 1.4) < 0.18
		if lit:
			draw_circle(Vector2(373, 298), 14.0, Color(0.36, 0.89, 0.56, 0.35))
		draw_circle(Vector2(373, 298), 7.5, COL["ol"])
		draw_circle(Vector2(373, 298), 5.5, Color("5be38f") if lit else Color("1f4a2a"))
		_gleam_canopy(t)
		_glints(t)
		# Breathing, a slow head tilt, blinks, and a coin flipped every 3 seconds.
		var breath := sin(t * 2.0) * 2.0
		var tilt := sin(t * 0.9) * 0.035
		var blink := 1.0
		var bt := fmod(t, 3.7)
		if bt < 0.12:
			blink = maxf(0.1, absf(bt - 0.06) / 0.06)
		var ft := fmod(t, 3.0)
		var flick := 1.0 - ft / 0.15 if ft < 0.15 else 0.0
		var hand := Vector2(296.0, 266.0 - flick * 10.0 + breath)
		var coin_h := 0.0
		var spin := 1.0
		if ft < 0.9:
			var kc := ft / 0.9
			coin_h = 4.0 * 110.0 * kc * (1.0 - kc)
			spin = cos(ft * 28.0)
		var coin := Vector2(hand.x + 2.0, hand.y - 12.0 - coin_h)
		_push(Vector2(0, breath))
		_outlined(BODY + ARM_L)
		_shapes(BODY_DETAIL + ARM_L_DETAIL)
		_pop()
		# The coin-flipping arm.
		var elbow := ELBOW_R + Vector2(0, breath)
		var arm := [
			["line", "sk", [SHOULDER_R, elbow], 14.0],
			["circle", "sk", elbow, 7.0],
			["line", "sk", [elbow, hand], 12.0],
			["poly", "sk", [hand + Vector2(-12, -2), hand + Vector2(12, -6), hand + Vector2(14, 4), hand + Vector2(-8, 8)]],
		]
		_push(Vector2(0, breath * 0.3))
		_outlined(arm)
		_pop()
		# The head.
		_push(NECK + Vector2(0, breath), tilt)
		_outlined(HEAD)
		_shapes(HEAD_DETAIL)
		for ex in [-14.0, 14.0]:   # glowing, squinting eyes
			_push(Vector2(ex, -46), 0.0, 1.0, blink)
			draw_circle(Vector2.ZERO, 9.0, Color(0.95, 0.88, 0.35, 0.2))
			draw_colored_polygon(PackedVector2Array([Vector2(-7, 0), Vector2(-3, -3.5), Vector2(4, -3.5), Vector2(7, 0), Vector2(3, 3), Vector2(-4, 3)]), COL["eye"])
			draw_rect(Rect2(-1.2, -3.0, 2.4, 6.0), COL["ol"])
			_pop()
		_pop()
		# The coin, spinning (squashed sideways as it turns).
		_push(coin, 0.0, maxf(0.12, absf(spin)), 1.0)
		draw_circle(Vector2.ZERO, 12.0, COL["ol"])
		draw_circle(Vector2.ZERO, 9.5, COL["gold"])
		draw_circle(Vector2.ZERO, 5.5, Color("c9a23a"))
		_pop()
		_pop()
