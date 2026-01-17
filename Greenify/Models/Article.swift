//
//  Article.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation

// MARK: - Educational Article Models

struct Article: Identifiable, Codable {
    let id: UUID
    let title: String
    let summary: String
    let content: String
    let category: ArticleCategory
    let readingTime: Int // in minutes
    let publishedDate: Date
    let imageSystemName: String
    let tags: [String]
    let difficulty: DifficultyLevel
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: publishedDate)
    }
}

enum ArticleCategory: String, CaseIterable, Codable {
    case climateChange = "Climate Change"
    case renewableEnergy = "Renewable Energy"
    case wasteReduction = "Waste Reduction"
    case sustainableLiving = "Sustainable Living"
    case conservation = "Conservation"
    case greenTechnology = "Green Technology"
    
    var icon: String {
        switch self {
        case .climateChange: return "thermometer.sun.fill"
        case .renewableEnergy: return "sun.max.fill"
        case .wasteReduction: return "trash.slash.fill"
        case .sustainableLiving: return "leaf.fill"
        case .conservation: return "drop.fill"
        case .greenTechnology: return "gear"
        }
    }
    
    var color: String {
        switch self {
        case .climateChange: return "red"
        case .renewableEnergy: return "yellow"
        case .wasteReduction: return "brown"
        case .sustainableLiving: return "green"
        case .conservation: return "blue"
        case .greenTechnology: return "purple"
        }
    }
}

enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var icon: String {
        switch self {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "orange"
        case .advanced: return "red"
        }
    }
}

// MARK: - Mock Articles Data

extension Article {
    static let mockArticles = [
        Article(
            id: UUID(),
            title: "Understanding Carbon Footprints",
            summary: "Learn what carbon footprints are and how your daily activities contribute to greenhouse gas emissions.",
            content: """
            A carbon footprint represents the total amount of greenhouse gases produced directly and indirectly by human activities, usually expressed in equivalent tons of carbon dioxide (CO2).

            ## What Contributes to Your Carbon Footprint?

            ### Transportation
            Transportation is often the largest contributor to an individual's carbon footprint. This includes:
            - Personal vehicles (cars, motorcycles)
            - Public transportation (buses, trains)
            - Air travel
            - Shipping and freight

            ### Energy Use
            The energy we use in our homes and workplaces significantly impacts our carbon footprint:
            - Electricity consumption
            - Heating and cooling
            - Water heating
            - Appliance usage

            ### Food and Diet
            Our food choices have a substantial environmental impact:
            - Meat production, especially beef, has high emissions
            - Local vs. imported foods
            - Food packaging and processing
            - Food waste

            ### Consumer Goods
            The products we buy and use contribute to our footprint:
            - Manufacturing processes
            - Packaging materials
            - Product lifecycle
            - Disposal methods

            ## Reducing Your Carbon Footprint

            Small changes in daily habits can make a significant difference:
            1. Use public transportation or bike when possible
            2. Reduce energy consumption at home
            3. Choose sustainable food options
            4. Buy less and choose quality products
            5. Recycle and compost properly

            Understanding your carbon footprint is the first step toward making more sustainable choices and contributing to climate action.
            """,
            category: .climateChange,
            readingTime: 5,
            publishedDate: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            imageSystemName: "leaf.fill",
            tags: ["carbon", "emissions", "sustainability", "climate"],
            difficulty: .beginner
        ),
        
        Article(
            id: UUID(),
            title: "The Power of Solar Energy",
            summary: "Discover how solar energy works and why it's becoming the world's fastest-growing renewable energy source.",
            content: """
            Solar energy harnesses the power of the sun to generate clean, renewable electricity. As technology advances and costs decrease, solar power is becoming increasingly accessible to homeowners and businesses worldwide.

            ## How Solar Energy Works

            ### Photovoltaic Cells
            Solar panels contain photovoltaic (PV) cells that convert sunlight directly into electricity:
            - Silicon-based cells absorb photons from sunlight
            - This creates an electric field that generates direct current (DC)
            - An inverter converts DC to alternating current (AC) for home use

            ### Solar Thermal Systems
            These systems use sunlight to heat water or air:
            - Collectors absorb solar radiation
            - Heat transfer fluid carries thermal energy
            - Used for water heating, space heating, and cooling

            ## Benefits of Solar Energy

            ### Environmental Impact
            - Zero greenhouse gas emissions during operation
            - Reduces dependence on fossil fuels
            - Minimal water usage compared to traditional power plants
            - Long lifespan with recyclable components

            ### Economic Advantages
            - Decreasing installation costs
            - Long-term energy savings
            - Government incentives and tax credits
            - Increased property values
            - Job creation in the renewable energy sector

            ### Energy Independence
            - Reduced reliance on grid electricity
            - Protection against rising energy costs
            - Energy storage options with battery systems
            - Distributed generation reduces transmission losses

            ## Challenges and Solutions

            ### Intermittency
            Solar power generation varies with weather and time of day:
            - Battery storage systems provide backup power
            - Grid integration balances supply and demand
            - Smart grid technology optimizes distribution

            ### Initial Costs
            While upfront costs can be significant:
            - Financing options make solar more accessible
            - Leasing programs require no upfront investment
            - Payback periods continue to decrease

            ## The Future of Solar

            Emerging technologies promise even greater efficiency:
            - Perovskite solar cells
            - Floating solar farms
            - Solar paint and flexible panels
            - Integration with smart home systems

            Solar energy represents a crucial component of our transition to a sustainable energy future, offering environmental benefits while becoming increasingly economically attractive.
            """,
            category: .renewableEnergy,
            readingTime: 8,
            publishedDate: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
            imageSystemName: "sun.max.fill",
            tags: ["solar", "renewable", "energy", "technology"],
            difficulty: .intermediate
        ),
        
        Article(
            id: UUID(),
            title: "Zero Waste Living: A Beginner's Guide",
            summary: "Start your journey toward zero waste with practical tips and strategies for reducing waste in your daily life.",
            content: """
            Zero waste living is a lifestyle that aims to reduce the amount of waste we send to landfills and incinerators. The goal is to redesign our consumption patterns to be more sustainable and circular.

            ## The 5 R's of Zero Waste

            ### 1. Refuse
            Say no to things you don't need:
            - Single-use items (straws, bags, utensils)
            - Promotional materials and freebies
            - Excessive packaging
            - Junk mail and paper receipts

            ### 2. Reduce
            Minimize what you do need:
            - Buy only what you'll actually use
            - Choose quality over quantity
            - Opt for digital alternatives
            - Share or borrow instead of buying

            ### 3. Reuse
            Find new purposes for items:
            - Repurpose glass jars for storage
            - Use old t-shirts as cleaning rags
            - Transform containers into planters
            - Donate items in good condition

            ### 4. Recycle
            Process materials into new products:
            - Learn your local recycling guidelines
            - Clean containers before recycling
            - Separate materials properly
            - Find specialized recycling programs

            ### 5. Rot
            Compost organic materials:
            - Food scraps and yard waste
            - Paper products (unbleached)
            - Natural fibers
            - Create nutrient-rich soil

            ## Getting Started

            ### Kitchen
            - Use reusable bags and containers
            - Buy in bulk to reduce packaging
            - Compost food scraps
            - Choose reusable water bottles and coffee cups

            ### Bathroom
            - Switch to bar soap and shampoo
            - Use bamboo toothbrushes
            - Try reusable cotton pads
            - Make your own cleaning products

            ### Wardrobe
            - Buy secondhand or sustainable brands
            - Repair and mend clothing
            - Organize clothing swaps
            - Choose quality pieces that last

            ## Common Challenges

            ### Convenience
            Zero waste can require more planning:
            - Prepare reusable items in advance
            - Find zero waste stores in your area
            - Batch cooking and meal planning
            - Build sustainable habits gradually

            ### Social Situations
            Navigating social expectations:
            - Bring your own containers to restaurants
            - Explain your choices when asked
            - Lead by example, not by preaching
            - Find like-minded communities

            ## Benefits Beyond Waste Reduction

            ### Financial Savings
            - Reduced consumption saves money
            - Buying in bulk is often cheaper
            - Repairing extends product life
            - Less storage needed for fewer items

            ### Health Benefits
            - Fewer chemicals from packaged products
            - More whole foods in diet
            - Increased awareness of consumption
            - Reduced exposure to toxins

            ### Environmental Impact
            - Reduced landfill waste
            - Lower carbon footprint
            - Conservation of natural resources
            - Support for sustainable businesses

            Remember, zero waste is a journey, not a destination. Start small, be patient with yourself, and celebrate progress along the way.
            """,
            category: .wasteReduction,
            readingTime: 10,
            publishedDate: Calendar.current.date(byAdding: .day, value: -21, to: Date()) ?? Date(),
            imageSystemName: "trash.slash.fill",
            tags: ["zero waste", "lifestyle", "reduce", "reuse"],
            difficulty: .beginner
        ),
        
        Article(
            id: UUID(),
            title: "Water Conservation at Home",
            summary: "Simple yet effective ways to reduce water consumption and protect this precious resource.",
            content: """
            Water is one of our most precious resources, yet it's often taken for granted. With growing populations and climate change affecting water availability, conservation has never been more important.

            ## Understanding Water Usage

            ### Household Water Consumption
            The average household uses water for:
            - Toilet flushing (24%)
            - Washing machines (16%)
            - Showers (17%)
            - Faucets (19%)
            - Leaks (12%)
            - Other uses (12%)

            ## Indoor Water Conservation

            ### Bathroom
            The bathroom typically accounts for about 60% of indoor water use:
            - Install low-flow showerheads and faucets
            - Take shorter showers (aim for 5 minutes or less)
            - Fix leaky toilets and faucets immediately
            - Consider dual-flush or low-flow toilets
            - Turn off water while brushing teeth or shaving

            ### Kitchen
            - Run dishwashers only with full loads
            - Use the appropriate water level for washing dishes
            - Fix dripping faucets
            - Install aerators on faucets
            - Keep drinking water in the refrigerator

            ### Laundry
            - Wash full loads when possible
            - Use appropriate water levels for load size
            - Choose cold water when possible
            - Upgrade to high-efficiency washing machines
            - Reuse towels and clothing when appropriate

            ## Outdoor Water Conservation

            ### Landscaping
            - Choose native and drought-resistant plants
            - Group plants with similar water needs
            - Use mulch to retain soil moisture
            - Install drip irrigation systems
            - Collect rainwater for garden use

            ### Lawn Care
            - Water early morning or late evening
            - Adjust sprinklers to avoid watering pavement
            - Raise mower height to reduce evaporation
            - Consider alternatives to traditional grass
            - Use a broom instead of hose for cleaning

            ## Advanced Conservation Techniques

            ### Greywater Systems
            Reuse water from sinks, showers, and washing machines:
            - Simple systems redirect water to gardens
            - More complex systems include filtration
            - Reduces freshwater demand
            - Requires proper installation and maintenance

            ### Rainwater Harvesting
            Collect and store rainwater for later use:
            - Rain barrels for small-scale collection
            - Cisterns for larger storage capacity
            - First-flush diverters improve water quality
            - Use for irrigation and non-potable needs

            ### Smart Technology
            - Smart irrigation controllers adjust watering based on weather
            - Leak detection systems alert you to problems
            - Smart meters track usage patterns
            - Apps help monitor and reduce consumption

            ## The Bigger Picture

            ### Environmental Benefits
            - Preserves freshwater ecosystems
            - Reduces strain on water treatment facilities
            - Protects groundwater resources
            - Maintains river and lake levels

            ### Economic Advantages
            - Lower water bills
            - Reduced energy costs (less hot water heating)
            - Increased property value with efficient fixtures
            - Potential rebates for conservation measures

            ### Community Impact
            - Ensures water availability during droughts
            - Reduces demand on municipal systems
            - Protects water quality for everyone
            - Sets positive example for others

            ## Getting Started

            1. **Audit Your Usage**: Check your water bill and identify high-usage areas
            2. **Fix Leaks First**: Address any dripping faucets or running toilets
            3. **Install Efficient Fixtures**: Start with low-cost options like aerators
            4. **Change Habits**: Implement water-saving behaviors
            5. **Monitor Progress**: Track your usage and celebrate improvements

            Every drop counts when it comes to water conservation. Small changes in daily habits can lead to significant water savings and environmental benefits.
            """,
            category: .conservation,
            readingTime: 7,
            publishedDate: Calendar.current.date(byAdding: .day, value: -28, to: Date()) ?? Date(),
            imageSystemName: "drop.fill",
            tags: ["water", "conservation", "home", "efficiency"],
            difficulty: .intermediate
        ),
        
        Article(
            id: UUID(),
            title: "Green Technology Innovations",
            summary: "Explore cutting-edge technologies that are revolutionizing sustainability and environmental protection.",
            content: """
            Green technology, or cleantech, encompasses innovations designed to reduce environmental impact while improving efficiency and sustainability. These technologies are reshaping industries and creating new opportunities for environmental protection.

            ## Emerging Green Technologies

            ### Carbon Capture and Storage (CCS)
            Technology to capture CO2 emissions and store them safely:
            - Direct air capture removes CO2 from atmosphere
            - Industrial capture prevents emissions at source
            - Underground storage in geological formations
            - Utilization converts CO2 into useful products

            ### Advanced Battery Technologies
            Next-generation energy storage solutions:
            - Solid-state batteries offer higher energy density
            - Flow batteries provide grid-scale storage
            - Organic batteries use sustainable materials
            - Recycling technologies recover valuable materials

            ### Artificial Intelligence for Sustainability
            AI applications in environmental protection:
            - Smart grid optimization reduces energy waste
            - Predictive maintenance extends equipment life
            - Climate modeling improves weather predictions
            - Resource optimization in manufacturing

            ### Biotechnology Solutions
            Living systems for environmental challenges:
            - Biofuels from algae and waste materials
            - Bioplastics from renewable resources
            - Bioremediation cleans contaminated environments
            - Synthetic biology creates custom organisms

            ## Transportation Innovations

            ### Electric Vehicles (EVs)
            - Improved battery range and charging speed
            - Wireless charging infrastructure
            - Vehicle-to-grid energy sharing
            - Autonomous electric vehicles

            ### Alternative Fuels
            - Hydrogen fuel cells for heavy transport
            - Sustainable aviation fuels
            - Ammonia as marine fuel
            - Synthetic fuels from renewable energy

            ### Smart Transportation Systems
            - Traffic optimization reduces emissions
            - Shared mobility platforms
            - Electric public transportation
            - Integrated multimodal transport

            ## Building and Construction

            ### Smart Buildings
            - IoT sensors optimize energy usage
            - Automated systems adjust lighting and temperature
            - Predictive maintenance prevents waste
            - Integration with renewable energy sources

            ### Sustainable Materials
            - Bio-based construction materials
            - Recycled and upcycled building components
            - Self-healing concrete reduces maintenance
            - Phase-change materials for thermal regulation

            ### Green Architecture
            - Passive house design minimizes energy needs
            - Living walls and green roofs
            - Natural ventilation and lighting
            - Water recycling systems

            ## Agriculture and Food

            ### Precision Agriculture
            - Drones monitor crop health
            - Sensors optimize irrigation and fertilization
            - AI predicts optimal planting and harvesting
            - Reduced chemical inputs

            ### Vertical Farming
            - Indoor growing reduces land use
            - LED lighting optimized for plant growth
            - Hydroponic and aeroponic systems
            - Year-round production with minimal water

            ### Alternative Proteins
            - Plant-based meat substitutes
            - Cultured meat from cell cultures
            - Insect protein farming
            - Fermentation-based proteins

            ## Waste Management

            ### Advanced Recycling
            - Chemical recycling breaks down plastics
            - AI-powered sorting systems
            - Molecular recycling creates virgin-quality materials
            - Blockchain tracking improves transparency

            ### Waste-to-Energy
            - Improved incineration with emissions control
            - Anaerobic digestion produces biogas
            - Pyrolysis converts waste to fuel
            - Plasma gasification handles difficult waste

            ## Water Technology

            ### Desalination Advances
            - Reverse osmosis efficiency improvements
            - Solar-powered desalination
            - Forward osmosis reduces energy needs
            - Graphene membranes increase performance

            ### Water Purification
            - Nanotechnology filters remove contaminants
            - UV-LED disinfection systems
            - Atmospheric water generation
            - Smart water quality monitoring

            ## Challenges and Opportunities

            ### Scaling Up
            - Moving from laboratory to commercial scale
            - Reducing costs through mass production
            - Building necessary infrastructure
            - Training workforce for new technologies

            ### Integration
            - Connecting different green technologies
            - Updating regulatory frameworks
            - Ensuring compatibility with existing systems
            - Managing transition periods

            ### Investment and Policy
            - Securing funding for development
            - Creating supportive policy environments
            - International cooperation on standards
            - Balancing innovation with regulation

            ## The Future Outlook

            Green technology continues to evolve rapidly, driven by:
            - Climate urgency and environmental awareness
            - Decreasing costs and improving performance
            - Supportive policies and regulations
            - Growing consumer demand for sustainable solutions

            These innovations offer hope for addressing environmental challenges while creating economic opportunities and improving quality of life. The key is continued investment in research, development, and deployment of these promising technologies.
            """,
            category: .greenTechnology,
            readingTime: 12,
            publishedDate: Calendar.current.date(byAdding: .day, value: -35, to: Date()) ?? Date(),
            imageSystemName: "gear",
            tags: ["technology", "innovation", "cleantech", "future"],
            difficulty: .advanced
        )
    ]
}