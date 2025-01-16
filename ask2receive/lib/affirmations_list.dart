import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> getAffirmations() async {
  try {
    String data = await rootBundle.loadString('assets/data/affirmations.txt');
    List<String> affirmations =
        data.split('\n').where((line) => line.trim().isNotEmpty).toList();
    return affirmations;
  } catch (e) {
    print("Error loading affirmations: $e");
    return [];
  }
}

Future<String> selectDailyAffirmation() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> affirmations = await getAffirmations();

  if (affirmations.isEmpty) {
    return "I am enough!"; // Default if file fails
  }

  Set<String> usedAffirmations =
      Set<String>.from(prefs.getStringList('usedAffirmations') ?? []);
  List<String> availableAffirmations =
      affirmations.where((a) => !usedAffirmations.contains(a)).toList();

  if (availableAffirmations.isEmpty) {
    usedAffirmations.clear(); // Reset if all affirmations are used
    availableAffirmations = affirmations;
  }

  final random = Random();
  String selectedAffirmation =
      availableAffirmations[random.nextInt(availableAffirmations.length)];
  usedAffirmations.add(selectedAffirmation);

  await prefs.setString('dailyAffirmation', selectedAffirmation);
  await prefs.setStringList('usedAffirmations', usedAffirmations.toList());

  return selectedAffirmation;
}

const List<String> affirmations = [
  "I am capable of amazing things.",
  "I am strong, confident, and capable!",
  "Today is a fresh start, full of opportunities.",
  "I can achieve anything I set my mind to.",
  "I am strong, confident, and resilient.",
  "Every challenge is an opportunity to grow.",
  "I am worthy of love and happiness.",
  "My potential is limitless.",
  "Every day, in every way, I am getting better and better.",
  "I am grateful for all that I have.",
  "I attract positivity and abundance into my life.",
  "I am enough just as I am.",
  "My mind is filled with positive and loving thoughts.",
  "I am surrounded by peace and love.",
  "I have the power to create change in my life.",
  "I am courageous and will stand up for what I believe in.",
  "I radiate confidence, self-respect, and inner harmony.",
  "My heart is open to receive love and kindness.",
  "I forgive myself and others easily.",
  "I am proud of all my accomplishments.",
  "My possibilities are endless.",
  "I am a magnet for miracles.",
  "My thoughts create my reality, and I am the master of my thoughts.",
  "I am healthy, wealthy, and wise.",
  "I am in charge of my happiness.",
  "I deserve all the good things life has to offer.",
  "Today is my day.",
  "I am confident, happy, healthy, and powerful.",
  "I deserve everything I want in life.",
  "I love myself unconditionally.",
  "I am competent, smart, and able.",
  "I am growing and changing for the better.",
  "I love the person I am becoming.",
  "Every day I am becoming a better version of myself.",
  "Today is a great day to be alive!.",
  "I am a strong and powerful person.",
  "I am naturally confident and at ease in my own life.",
  "I am worthy, wonderful, and wise.",
  "I am clear and confident in my personal choices.",
  "Confidence comes naturally to me.",
  "My body, mind, and spirit are powerful and profound.",
  "Every day my confidence is growing.",
  "I am motivated, positive, and confident in my life vision.",
  "I have complete confidence in myself and my path.",
  "I am confident in my skills and gifts.",
  "I radiate love and self-confidence.",
  "I am humble yet confident.",
  "I live in the present wonderful moment and trust in my future.",
  "I face challenging situations with confidence, courage, and conviction.",
  "I am confident in my unique gifts and talents and I share them proudly with the world.",
  "I am self-sufficient, creative, and resilient.",
  "All of my problems have solutions.",
  "There is no one better to be than me.",
  "I embody confidence.",
  "I am confident in my ability to change my life.",
  "I am at peace in my life.",
  "I am getting better every day and in every way.",
  "Great things are happening to me every day.",
  "I have all I need to make today a great day.",
  "I radiate confidence.",
  "I am enough.",
  "I conquer every obstacle to create my dream life.",
  "Everything is going according to plan.",
  "My past will not dictate my future.",
  "I always see the good in others and in myself.",
  "I know I have the ability to achieve my goals in life.",
  "I am confident with my life plan and the way things are going.",
  "I deserve the love I am given.",
  "I let go of the negative feelings about myself and accept all that is good.",
  "I feel glorious, dynamic energy. I am active and alive.",
  "Abundance flows freely through me.",
  "My experiences are essential for my growth and development.",
  "I am worthy because I honor who I am.",
  "I am open to new and beautiful changes.",
  "Life is bringing me beautiful experiences.",
  "Nobody but me decides how I feel.",
  "I’m in charge of my thoughts, and I will judge myself appropriately.",
  "I got this!",
  "I have the power to shape my ideal reality.",
  "I create the life I desire with my good feelings.",
  "Everything is always working out well for me.",
  "When I feel happy I manifest more reasons to be happy.",
  "I am willing to be happy now.",
  "I accept that happiness is my true nature.",
  "I am worthy of feeling happy.",
  "My happiness comes from within me.",
  "I create my happiness by accepting every part of myself with unconditional love.",
  "Joy is the essence of my being.",
  "I see so many positives in my life.",
  "I am constantly creating everything my heart desires.",
  "I experience joy in everything I do.",
  "I feel happy with myself as a person.",
  "I give myself permission to enjoy myself.",
  "I allow myself to feel good.",
  "The life I’ve always dreamed of is created by my choice to be joyful now.",
  "Following my joy reveals the path to my best life.",
  "My choice to be happy keeps me in perfect health.",
  "The happiness I feel is felt by everyone around me.",
  "I create the possibility of happiness for others by being happy.",
  "I am meant to live a happy life.",
  "My inner joy expands when I share it with others.",
  "All the good in my life comes to me as result of my willingness to find happiness in each moment.",
  "My happiness is reflected back to me in everything I attract.",
  "My inner joy is the source of all the good in my life.",
  "I experience joy in everything I do.",
  "I am positive. I am loved. I am enough.",
  "I start every day with gratitude and thanks.",
  "Today is full of opportunity.",
  "I am grateful for waking up today. I am grateful for what I have. I am grateful for being here.",
  "I am confidently making choices that will create a better future.",
  "Today I am working toward creating the life of my dreams.",
  "I have everything I need.",
  "Life is full of meaning. I will make the most of this day.",
  "Today I will be fabulous.",
  "Never talk negative. Use words like yes, success, and I can.",
  "I am positive and create joy and happiness for others.",
  "I have a positive attitude and accept with an open heart everything that comes.",
  "I feel healthy, wealthy, and wise.",
  "I focus on what I can control. I let go of the rest.",
  "I live the best life, in the best home, with the love of my life.",
  "I am present, powerful, and calm.",
  "I am focused on my family, relationships, and career.",
  "My dreams, goals, and challenges will be achieved through focus and hard work.",
  "I am motivated and have high energy.",
  "I feel so much confidence in my skin.",
  "I am a success magnet and all my desires come true.",
  "I am succeeding in life.",
  "I know I can achieve anything I want in life.",
  "Prosperity flows to and through me.",
  "I will succeed by attracting people who can help me.",
  "I know a positive attitude can bring me success.",
  "I am full of vitality. My confidence, positive attitude, and self - belief are my biggest assets to take me a step closer to my success.",
  "I am happy with who I am and can be.",
  "Today I am going to bid farewell to old bad habits and welcome a positive change in my life.",
  "I am worthy enough to follow my dreams and manifest my desires.",
  "Today I am prepared.I am prepared for success, love, happiness, peace, joy, and abundance! I am prepared for my wildest dreams to come true.",
  "I am the architect of my fate.I can achieve what I have dreamt for myself.",
  "I am harder than all the challenges and hurdles lying in my way.",
  "I am blessed to have everything in my life to make it successful.",
  "I am capable of attracting daily abundance.",
  "I am attuned to the abundance of success.",
  "I celebrate the abundance of everything in my life.",
  "I believe in myself.",
  "I am open to receiving unexpected opportunities.",
  "I choose to embrace the mystery of life.",
  "I am my best source of motivation.",
  "I am capable of achieving greatness.",
  "I am grateful for the abundance that I have and the abundance that’s on its way.",
  "I attract miracles into my life.",
  "I achieve whatever I set my mind to.",
  "I am open to limitless possibilities.",
  "I continue to climb higher, there are no limits to what I can achieve.",
  "I am a strong individual who attracts success and happiness.",
  "I let go of old, negative beliefs that have stood in the way of my success.",
  "The world needs my light and I am not afraid to shine.",
  "Every day I become more confident, powerful, and successful.",
  "I am worthy of all the good life has to offer, and I deserve to be successful.",
  "I am always open - minded and eager to explore new avenues to success.",
  "I am a powerful creator.I create the life I want and enjoy it.",
  "I am surrounded by positive, supportive people who believe in me.",
  "I stay focused on my vision and pursue my daily work with passion.",
  "I take pride in my ability to make worthwhile contributions to the world.",
  "Everywhere I look, I see prosperity.",
  "As I allow more abundance into my life, more doors open for me.",
  "Wealth constantly flows into my life.",
  "My actions create constant wealth, prosperity, and abundance.",
  "I am living my life in a state of complete abundance.",
  "I believe that I can do anything.",
  "I have goals and dreams that I am going to achieve.",
  "I am a goal - getter and won’t stop at anything to achieve my goals.",
  "I am committed to achieving success in every area of my life.",
  "I choose positivity.",
  "I am worthy of my dream job and am creating the career of my dreams.",
  "I believe in me.",
  "I easily accomplish all of my goals.",
  "I am enough.",
  "I attract money to me easily and effortlessly.",
  "I am a money magnet.",
  "I release all resistance to attracting money.",
  "I accept and receive unexpected money.",
  "I am a magnet for money. Prosperity is drawn to me.",
  "Money comes to me easily and effortlessly.",
  "Wealth constantly flows into my life.",
  "My finances improve beyond my dreams.",
  "I am attracting money at this very moment.",
  "I am open and receptive to all the wealth life brings me.",
  "I attract money happily in my life.",
  "I attract money beyond my wildest dreams.",
  "I am open to receiving money in my life.",
  "The more I focus on joy, the more money I will make.",
  "I attract money to give to others.",
  "Money is energy, and it flows into my life constantly.",
  "Money flows to me in expected and unexpected ways.",
  "I have the power to attract wealth and money into my life.",
  "Money is abundant, and I attract it naturally.",
  "Money is unlimited, and my prosperity is unlimited.",
  "Money is pouring into my life.",
  "An abundance of money is flowing into my life right now.",
  "My mind is a powerful magnet for wealth and abundance.",
  "Money flows to me freely as I move through this world.",
  "I will attain all the riches that I desire with time.",
  "I am on my way to becoming wealthy.",
  "Everything I need to build wealth is available to me right now.",
  "There is money all around me; I just have to grab it.",
  "I am a magnet that can attract money in any endeavor I undertake.",
  "I love attracting money.",
  "Money falls into my lap in miraculous ways.",
  "People love giving me money.",
  "I trust that more money is coming to me.",
  "I am aligned with the energy of wealth and abundance.",
  "I allow money to flow easily to me.",
  "Money is being drawn to me in every moment.",
  "I am so grateful for the ability to manifest money when I want it.",
  "I am creating an abundant future with my thoughts today.",
  "More money is lining up for me right this minute.",
  "I choose to focus on money flowing to me with ease.",
  "I can see examples of abundance all around.",
  "Money chooses me, always.",
  "I visualize myself having money, and I receive more money.",
  "Money is drawn to me, always.",
  "Money simply falls into my lap.",
  "I attract wealth to me from all directions.",
  "I attract massive amounts of money to me.",
  "I breathe in abundance.",
  "I allow prosperity to flow into my life.",
  "I am capable of overcoming any money obstacles that stand in my way.",
  "I boldly conquer my money goals.",
  "I am the master of my wealth.",
  "I can handle large sums of money.",
  "I am an excellent money manager.",
  "I believe money is important.",
  "I know that money is freedom.",
  "My capacity to hold and grow money expands every day.",
  "I always have more money coming in than going out.",
  "My income is always higher than my expenses.",
  "I enjoy managing and investing my money.",
  "My finances improve beyond anything I could ever imagine.",
  "I am wealthy and living on my own terms.",
  "Money is a tool that can change my life for the better.",
  "I control money; money doesn’t control me.",
  "I am a capable person that can tackle all money obstacles.",
  "I have the power to be a financially successful person.",
  "I have the power to improve my relationship with money.",
  "I can find the positive in my money situation.",
  "I believe in my ability to use the money that comes into my life to meet my financial goals.",
  "It is within my power to create a successful financial future.",
  "With hard work, I can build the financial future that I desire.",
  "I have the discipline to make hard financial choices now to enjoy an easier life later on.",
  "I am in control of my spending.",
  "My debt doesn’t control me; I manage it.",
  "Making choices to build wealth today can allow me to create the life I desire.",
  "I have the ability to learn how to manage my money better.",
  "I am excited to keep my finances on the right path.",
  "My actions perpetuate a life of prosperity.",
  "I can track my expenses and stick to a budget.",
  "I can make my dreams a reality with careful budgeting.",
  "I am passionate about building wealth and recognize all the value that it brings to my life.",
  "I am capable of managing large sums of money.",
  "I am responsible with money and manage it wisely.",
  "I am successful with money.",
  "I am one step closer to my financial goals.",
  "Financial success belongs to me, and I accept it now.",
  "Every action I take will plant the seeds for wealth.",
  "I make wise financial decisions and trust my process.",
  "I am ready to make my financial goals and dreams a reality.",
  "I am excited to start and establish my money-making goals.",
  "I am a successful money saver.",
  "It’s easy for me to change my money story.",
  "I reclaim my money power.",
  "I choose to be organized and responsible with money.",
  "No matter how I feel or what I do, money gets to be easy.",
  "Being rich is a part of who I am.",
  "Money is a tool, and I am going to learn to use it well.",
  "I am in control of my financial life.",
  "I overcome all obstacles that lie in my way of financial success.",
  "I will be debt-free. I have the power to make it happen.",
  "My future self will thank me for saving money today.",
  "My savings will continue to grow, and I will be financially secure.",
  "I will build an emergency fund to safeguard myself.",
  "I enjoy the challenge of saving more money.",
  "Every dollar saved puts me closer to financial freedom.",
  "I make money easily.",
  "I deserve to make more money.",
  "I am worthy of making more money.",
  "I embrace new avenues of income.",
  "I welcome an unlimited source of income and wealth in my life.",
  "I constantly attract opportunities that create more money.",
  "I constantly discover new sources of income.",
  "My income is growing higher and higher.",
  "I attract enough income to pay for the lifestyle I want.",
  "I get rich doing what I love.",
  "My bank account is constantly filled with money.",
  "There are no limits to the money I can make.",
  "The more fun I have, the more money I make.",
  "My income is constantly increasing.",
  "My income will exceed my expenses.",
  "Money is an abundant resource that I can earn.",
  "My income has unlimited potential.",
  "I accept the flow of money from multiple sources.",
  "My job provides the opportunity to work towards my financial goals.",
  "I enjoy making money and genuinely love my work.",
  "I can leverage my skills to bring in more money at any time.",
  "I believe in my ability to earn more money.",
  "I deserve the opportunity to earn more than I make today.",
  "Every day is a fresh opportunity to earn more money.",
  "I am capable of turning my skills and expertise into income.",
  "My hard work will bring me money.",
  "My skills and hard work bring me wealth, and I am grateful and respectful of that.",
  "Making money is a positive endeavor that serves me, my family, and my community.",
  "There are countless opportunities to make more money in my life.",
  "The money that I have invested will be returned to me ten-fold.",
  "Manifesting money is easy because I’m ready to put in the work.",
  "I have fun earning money.",
  "I am so excited about receiving more money.",
  "I am so grateful for the opportunity to manifest more income.",
  "It’s easy to make money.",
  "I am easily creating more money and abundance.",
  "Money comes to me in fun, easy and surprising ways!",
  "There is no limit to the amount of money I am capable of earning.",
  "Every dollar that flows to me now works for me, to earn more money.",
  "I always have enough money.",
  "I believe there is enough money for everyone.",
  "I am financially free.",
  "I have more than enough money.",
  "Money is abundant to me.",
  "I always have enough money to fulfill my needs.",
  "The universe provides enough money for everyone.",
  "I can become financially free.",
  "Financial freedom is not just a dream; it will be my reality.",
  "I have enough money to enjoy my day-to-day life freely.",
  "I have more money than I could ever spend.",
  "I am what a wealthy person looks like.",
  "I choose to stay focused on abundance no matter what.",
  "I always have more than enough for everything I need.",
  "I am wealthy!",
  "I can easily afford anything I want. ",
  "I am grateful for money.",
  "I love money because money loves me.",
  "I am worthy of the wealth I desire.",
  "I release all negative energy over money.",
  "Money is the root of joy and comfort.",
  "Money and spirituality can co-exist in harmony.",
  "Money and love can be friends.",
  "I am at peace with having a lot of money.",
  "I am grateful for all the money I have now.",
  "I have a positive money mindset.",
  "I deserve to be rich.",
  "I deserve money in my life.",
  "I am grateful for all that money brings me.",
  "I let go of all my limiting beliefs around money.",
  "I let go of all my fears around money.",
  "I know anyone can be wealthy, including me.",
  "Every day, I choose money and wealth.",
  "All the money I have brings me joy.",
  "I am worthy of a wealthy life.",
  "My wealth comes from being honest and authentic in everything I do.",
  "If others can be wealthy, so can I.",
  "I deserve a prosperous life.",
  "I am worthy of a solid financial foundation.",
  "I am not poor; I am on the path to a wealthy life.",
  "I gracefully surrender all of my resistance to wealth.",
  "I am worthy of financial security and freedom.",
  "Financial security brings me peace.",
  "I am thankful for the comfort that having money can bring to me when I manage it well.",
  "I enjoy money.",
  "I am grateful for the money I already have and the money that’s on its way to me now.",
  "I embrace a life of abundance and positive thinking.",
  "I am so happy and grateful that money flows to me easily and effortlessly.",
  "My relationship with money gets better and better every day.",
  "I am worthy of money.",
  "It is safe to be wealthy.",
  "I trust money.",
  "I deserve to be financially rewarded.",
  "I choose to think only positive thoughts about money.",
  "I choose to feel wealthy right now.",
  "I am healing my relationship with money.",
  "Having money makes me feel calm and confident.",
  "I choose to believe I deserve to have plenty of money.",
  "Financial well-being is my new reality.",
  "My positive attitude is attracting money.",
  "I am thankful for the abundance and prosperity in my life.",
  "I give myself permission to prosper and build wealth and to be happy about it.",
  "I bless all rich, wealthy, and abundant people.",
  "I am grateful for the wealth that is inside of me.",
  "I embrace all positive associations to money, wealth, abundance, and prosperity.",
  "Money affirmations for using my wealth.",
  "I am generous with my money.",
  "I change the world with my money.",
  "I love to give money a good home.",
  "I use money to better my life and the lives of others.",
  "Money is my servant.",
  "The money I contribute always comes back to me multiplied.",
  "I use money to improve the lives of others.",
  "My money works hard for me, to make me more and more money.",
  "I use money to improve my life.",
  "Money creates a positive impact on my life and the life of others.",
  "The more value I contribute, the more money I will make.",
  "I am grateful that I can contribute my money to the economy.",
  "I am happy to pay my bills for all that they provide me.",
  "The money I spend and earn makes me happy.",
  "I can use money to create a better life.",
  "Money can expand the opportunities of my life.",
  "Through thoughtful generosity, more money will flow back to me.",
  "I have the ability to spend money on the things that matter to me most.",
  "I am happy when I spend my money responsibly.",
  "Having money opens me to opportunities and new experiences.",
  "I can use money to change the world for the better.",
  "I choose to spend my money wisely.",
  "Money is used to provide good things for my life and the lives of the people I love.",
  "As I earn money, I am equipped to give and serve generously.",
  "Money well-spent is a source of good and positive things.",
  "Because I have money, I can give and serve generously.",
  "I will be mindful of my wealth so that it can serve me and those around me.",
  "My money allows me to have a life I love.",
  "Every dollar I spend comes back to me multiplied.",
  "I love the freedom that comes with financial abundance.",
  "Money is good because I use it for good things.",
  "Being wealthy gives me the power to help countless people in this world.",
  "The more I give, the wealthier I become.",
  "People benefit from my wealth & abundance.",
  "Prosperity within me, prosperity around me.",
  "Money is energy, so money is good.",
  "I am abundant, rich, wealthy, deserving, worthy.",
  "My life is full  of wealth beyond money.",
  "Money is in my mind. My mind creates money.",
  "I will be healthy, wealthy, and happy.",
  "I am happy, healthy, and wealthy.",
  "I love money, and money loves me.",
  "Money comes easily, frequently, and abundantly.",
  "Every day, in every way, I am becoming richer and more prosperous.",
  "I think like a millionaire. I act like a millionaire, I feel like a millionaire, I am a millionaire.",
  "Abundance within me, abundance around me.",
  "I radiate prosperity, money, and wealth."
];
