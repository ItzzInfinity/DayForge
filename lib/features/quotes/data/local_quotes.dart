import '../domain/quotes.dart';

/// Bundled fallback quotes — at least one per day of the year (365), so the
/// daily rotation never repeats within a year even fully offline. Famous
/// lines carry their author; short proverb-style lines are unattributed.
const localQuotes = <Quote>[
  Quote('A journey of a thousand miles begins with a single step.', 'Lao Tzu'),
  Quote('It does not matter how slowly you go as long as you do not stop.',
      'Confucius'),
  Quote('We are what we repeatedly do. Excellence, then, is not an act, '
      'but a habit.', 'Will Durant'),
  Quote('The secret of getting ahead is getting started.', 'Mark Twain'),
  Quote('Well begun is half done.', 'Aristotle'),
  Quote('It always seems impossible until it is done.', 'Nelson Mandela'),
  Quote('Whether you think you can, or you think you can\'t — you\'re right.',
      'Henry Ford'),
  Quote('Success is the sum of small efforts, repeated day in and day out.',
      'Robert Collier'),
  Quote('The best way out is always through.', 'Robert Frost'),
  Quote('Do what you can, with what you have, where you are.',
      'Theodore Roosevelt'),
  Quote('Fall seven times, stand up eight.', 'Japanese proverb'),
  Quote('Little by little, one travels far.'),
  Quote('The best time to plant a tree was twenty years ago. '
      'The second best time is now.', 'Chinese proverb'),
  Quote('Courage is not the absence of fear, but the triumph over it.',
      'Nelson Mandela'),
  Quote('What you do today can improve all your tomorrows.', 'Ralph Marston'),
  Quote('Don\'t watch the clock; do what it does. Keep going.',
      'Sam Levenson'),
  Quote('Start where you are. Use what you have. Do what you can.',
      'Arthur Ashe'),
  Quote('Motivation gets you going, habit keeps you growing.'),
  Quote('Discipline is choosing between what you want now and what you '
      'want most.'),
  Quote('You don\'t have to be great to start, but you have to start '
      'to be great.', 'Zig Ziglar'),
  Quote('Action is the foundational key to all success.', 'Pablo Picasso'),
  Quote('Dripping water hollows out stone, not through force but through '
      'persistence.', 'Ovid'),
  Quote('He who has a why to live can bear almost any how.',
      'Friedrich Nietzsche'),
  Quote('Energy and persistence conquer all things.', 'Benjamin Franklin'),
  Quote('Perseverance is not a long race; it is many short races one '
      'after the other.', 'Walter Elliot'),
  Quote('Great things are done by a series of small things brought '
      'together.', 'Vincent van Gogh'),
  Quote('The man who moves a mountain begins by carrying away small '
      'stones.', 'Confucius'),
  Quote('Quality is not an act, it is a habit.'),
  Quote('You miss 100% of the shots you don\'t take.', 'Wayne Gretzky'),
  Quote('I have not failed. I\'ve just found 10,000 ways that won\'t work.',
      'Thomas Edison'),
  Quote('Our greatest glory is not in never falling, but in rising every '
      'time we fall.', 'Confucius'),
  Quote('If you\'re going through hell, keep going.'),
  Quote('Believe you can and you\'re halfway there.', 'Theodore Roosevelt'),
  Quote('Everything you\'ve ever wanted is on the other side of fear.',
      'George Addair'),
  Quote('Hardships often prepare ordinary people for an extraordinary '
      'destiny.', 'C.S. Lewis'),
  Quote('The future depends on what you do today.', 'Mahatma Gandhi'),
  Quote('Small deeds done are better than great deeds planned.',
      'Peter Marshall'),
  Quote('One day or day one. You decide.'),
  Quote('A year from now you may wish you had started today.', 'Karen Lamb'),
  Quote('The difference between try and triumph is a little umph.'),
  Quote('Done is better than perfect.'),
  Quote('Every accomplishment starts with the decision to try.'),
  Quote('Progress, not perfection.'),
  Quote('Today\'s effort is tomorrow\'s strength.'),
  Quote('You are one habit away from a different life.'),
  Quote('Consistency is what transforms average into excellence.'),
  Quote('The pain of discipline weighs ounces; the pain of regret weighs '
      'tons.', 'Jim Rohn'),
  Quote('Either you run the day, or the day runs you.', 'Jim Rohn'),
  Quote('Success is nothing more than a few simple disciplines, practiced '
      'every day.', 'Jim Rohn'),
  Quote('Take care of the minutes and the hours will take care of '
      'themselves.', 'Lord Chesterfield'),
  Quote('Lost time is never found again.', 'Benjamin Franklin'),
  Quote('You may delay, but time will not.', 'Benjamin Franklin'),
  Quote('How we spend our days is, of course, how we spend our lives.',
      'Annie Dillard'),
  Quote('The best preparation for tomorrow is doing your best today.',
      'H. Jackson Brown Jr.'),
  Quote('Amateurs sit and wait for inspiration. The rest of us just get '
      'up and go to work.', 'Stephen King'),
  Quote('Inspiration exists, but it has to find you working.',
      'Pablo Picasso'),
  Quote('Genius is one percent inspiration and ninety-nine percent '
      'perspiration.', 'Thomas Edison'),
  Quote('There are no shortcuts to any place worth going.', 'Beverly Sills'),
  Quote('Nothing will work unless you do.', 'Maya Angelou'),
  Quote('You can\'t use up creativity. The more you use, the more you '
      'have.', 'Maya Angelou'),
  Quote('If you want to lift yourself up, lift up someone else.',
      'Booker T. Washington'),
  Quote('A river cuts through rock not because of its power, but because '
      'of its persistence.', 'Jim Watkins'),
  Quote('Strength does not come from what you can do. It comes from '
      'overcoming the things you once thought you couldn\'t.',
      'Rikki Rogers'),
  Quote('The only bad workout is the one that didn\'t happen.'),
  Quote('Sweat today, shine tomorrow.'),
  Quote('One tick at a time — that\'s how streaks are built.'),
  Quote('Your future self is watching you right now through memories.'),
  Quote('Show up. Especially when you don\'t feel like it.'),
  Quote('Habits are the compound interest of self-improvement.',
      'James Clear'),
  Quote('You do not rise to the level of your goals. You fall to the '
      'level of your systems.', 'James Clear'),
  Quote('Every action you take is a vote for the type of person you wish '
      'to become.', 'James Clear'),
  Quote('Make it obvious. Make it attractive. Make it easy. Make it '
      'satisfying.', 'James Clear'),
  Quote('Rome wasn\'t built in a day, but they were laying bricks every '
      'hour.', 'John Heywood (adapted)'),
  Quote('Don\'t break the chain.', 'Jerry Seinfeld (attributed)'),
  Quote('First we make our habits, then our habits make us.'),
  Quote('Win the morning, win the day.'),
  Quote('A little progress each day adds up to big results.'),
  Quote('The days are long, but the years are short.', 'Gretchen Rubin'),
  Quote('What gets measured gets managed.'),
  Quote('Starve your distractions, feed your focus.'),
  Quote('Direction is more important than speed.'),
  Quote('Slow progress is still progress.'),
  Quote('Doubt kills more dreams than failure ever will.', 'Suzy Kassem'),
  Quote('Whatever you are, be a good one.'),
  Quote('Act as if what you do makes a difference. It does.',
      'William James'),
  Quote('Begin anywhere.', 'John Cage'),
  Quote('The obstacle is the way.'),
  Quote('What stands in the way becomes the way.', 'Marcus Aurelius'),
  Quote('You have power over your mind — not outside events. Realize '
      'this, and you will find strength.', 'Marcus Aurelius'),
  Quote('Waste no more time arguing about what a good person should be. '
      'Be one.', 'Marcus Aurelius'),
  Quote('Very little is needed to make a happy life; it is all within '
      'yourself.', 'Marcus Aurelius'),
  Quote('No man is free who is not master of himself.', 'Epictetus'),
  Quote('First say to yourself what you would be; and then do what you '
      'have to do.', 'Epictetus'),
  Quote('It\'s not that we have a short time to live, but that we waste '
      'much of it.', 'Seneca'),
  Quote('Luck is what happens when preparation meets opportunity.',
      'Seneca'),
  Quote('Begin at once to live, and count each separate day as a '
      'separate life.', 'Seneca'),
  Quote('While we wait for life, life passes.', 'Seneca'),
  Quote('Difficulties strengthen the mind, as labor does the body.',
      'Seneca'),
  Quote('The impediment to action advances action.'),
  Quote('Do the hard thing first.'),
  Quote('Eat the frog: do the worst task before breakfast of excuses.'),
  Quote('Someday is not a day of the week.'),
  Quote('If it\'s important, you\'ll find a way. If not, you\'ll find an '
      'excuse.'),
  Quote('Excuses don\'t build empires.'),
  Quote('Dream big. Start small. Act now.', 'Robin Sharma'),
  Quote('Change is hardest at the beginning, messiest in the middle and '
      'best at the end.', 'Robin Sharma'),
  Quote('All change is hard at first, messy in the middle and gorgeous '
      'at the end.'),
  Quote('An ounce of practice is worth more than tons of preaching.',
      'Mahatma Gandhi'),
  Quote('Live as if you were to die tomorrow. Learn as if you were to '
      'live forever.', 'Mahatma Gandhi'),
  Quote('Strength does not come from physical capacity. It comes from '
      'an indomitable will.', 'Mahatma Gandhi'),
  Quote('In a gentle way, you can shake the world.', 'Mahatma Gandhi'),
  Quote('Be the change that you wish to see in the world.',
      'Mahatma Gandhi (attributed)'),
  Quote('Arise, awake, and stop not till the goal is reached.',
      'Swami Vivekananda'),
  Quote('Take up one idea. Make that one idea your life.',
      'Swami Vivekananda'),
  Quote('All power is within you; you can do anything and everything.',
      'Swami Vivekananda'),
  Quote('Talk to yourself once in a day, otherwise you may miss meeting '
      'an excellent person in this world.', 'Swami Vivekananda'),
  Quote('You have the right to work, but never to the fruit of work.',
      'Bhagavad Gita'),
  Quote('Man is made by his belief. As he believes, so he is.',
      'Bhagavad Gita'),
  Quote('There is nothing lost or wasted in this life.', 'Bhagavad Gita'),
  Quote('A person can rise through the efforts of his own mind.',
      'Bhagavad Gita'),
  Quote('Better indeed is knowledge than mechanical practice.',
      'Bhagavad Gita'),
  Quote('Patience is bitter, but its fruit is sweet.',
      'Jean-Jacques Rousseau'),
  Quote('He that can have patience can have what he will.',
      'Benjamin Franklin'),
  Quote('Adopt the pace of nature: her secret is patience.',
      'Ralph Waldo Emerson'),
  Quote('What lies behind us and what lies before us are tiny matters '
      'compared to what lies within us.', 'Ralph Waldo Emerson'),
  Quote('Do not go where the path may lead, go instead where there is no '
      'path and leave a trail.', 'Ralph Waldo Emerson'),
  Quote('The only person you are destined to become is the person you '
      'decide to be.', 'Ralph Waldo Emerson'),
  Quote('Once you make a decision, the universe conspires to make it '
      'happen.', 'Ralph Waldo Emerson'),
  Quote('Write it on your heart that every day is the best day in the '
      'year.', 'Ralph Waldo Emerson'),
  Quote('The mind is everything. What you think you become.'),
  Quote('Each morning we are born again. What we do today is what '
      'matters most.'),
  Quote('No matter how hard the past, you can always begin again.'),
  Quote('The trouble is, you think you have time.'),
  Quote('Drop by drop is the water pot filled.', 'Dhammapada'),
  Quote('However many holy words you read, what good will they do you if '
      'you do not act on upon them?', 'Dhammapada'),
  Quote('Better than a thousand hollow words is one word that brings '
      'peace.', 'Dhammapada'),
  Quote('You yourself must strive. The Buddhas only point the way.',
      'Dhammapada'),
  Quote('The best revenge is massive success.', 'Frank Sinatra (attributed)'),
  Quote('If you can dream it, you can do it.', 'Walt Disney (attributed)'),
  Quote('The way to get started is to quit talking and begin doing.',
      'Walt Disney'),
  Quote('All our dreams can come true, if we have the courage to pursue '
      'them.', 'Walt Disney'),
  Quote('It\'s kind of fun to do the impossible.', 'Walt Disney'),
  Quote('Keep moving forward.'),
  Quote('When you reach the end of your rope, tie a knot in it and hang '
      'on.', 'Franklin D. Roosevelt'),
  Quote('The only limit to our realization of tomorrow is our doubts of '
      'today.', 'Franklin D. Roosevelt'),
  Quote('Do one thing every day that scares you.',
      'Eleanor Roosevelt (attributed)'),
  Quote('No one can make you feel inferior without your consent.',
      'Eleanor Roosevelt'),
  Quote('The future belongs to those who believe in the beauty of their '
      'dreams.', 'Eleanor Roosevelt'),
  Quote('With the new day comes new strength and new thoughts.',
      'Eleanor Roosevelt'),
  Quote('It is never too late to be what you might have been.',
      'George Eliot (attributed)'),
  Quote('Our doubts are traitors, and make us lose the good we oft might '
      'win, by fearing to attempt.', 'William Shakespeare'),
  Quote('Things won are done; joy\'s soul lies in the doing.',
      'William Shakespeare'),
  Quote('How poor are they that have not patience! What wound did ever '
      'heal but by degrees?', 'William Shakespeare'),
  Quote('Screw your courage to the sticking-place.', 'William Shakespeare'),
  Quote('To climb steep hills requires slow pace at first.',
      'William Shakespeare'),
  Quote('The harder the conflict, the more glorious the triumph.',
      'Thomas Paine'),
  Quote('That which we obtain too easily, we esteem too lightly.',
      'Thomas Paine'),
  Quote('I am not afraid of storms, for I am learning how to sail my '
      'ship.', 'Louisa May Alcott'),
  Quote('Have regular hours for work and play; make each day both useful '
      'and pleasant.', 'Louisa May Alcott'),
  Quote('Far away there in the sunshine are my highest aspirations. I '
      'may not reach them, but I can look up and see their beauty.',
      'Louisa May Alcott'),
  Quote('It is not the mountain we conquer but ourselves.',
      'Edmund Hillary'),
  Quote('Because it\'s there.', 'George Mallory'),
  Quote('The summit is what drives us, but the climb itself is what '
      'matters.', 'Conrad Anker'),
  Quote('Mountains have a way of dealing with overconfidence.',
      'Hermann Buhl'),
  Quote('There is no such thing as bad weather, only unsuitable '
      'clothing.', 'Alfred Wainwright'),
  Quote('Champions keep playing until they get it right.', 'Billie Jean King'),
  Quote('Pressure is a privilege.', 'Billie Jean King'),
  Quote('You have to expect things of yourself before you can do them.',
      'Michael Jordan'),
  Quote('I\'ve failed over and over and over again in my life. And that '
      'is why I succeed.', 'Michael Jordan'),
  Quote('Talent wins games, but teamwork and intelligence win '
      'championships.', 'Michael Jordan'),
  Quote('Never say never, because limits, like fears, are often just an '
      'illusion.', 'Michael Jordan'),
  Quote('Hard work beats talent when talent doesn\'t work hard.',
      'Tim Notke'),
  Quote('It\'s not whether you get knocked down; it\'s whether you get '
      'up.', 'Vince Lombardi'),
  Quote('Winners never quit and quitters never win.', 'Vince Lombardi'),
  Quote('Perfection is not attainable, but if we chase perfection we can '
      'catch excellence.', 'Vince Lombardi'),
  Quote('The only place success comes before work is in the dictionary.',
      'Vince Lombardi'),
  Quote('Practice does not make perfect. Only perfect practice makes '
      'perfect.', 'Vince Lombardi'),
  Quote('You are never really playing an opponent. You are playing '
      'yourself.', 'Arthur Ashe'),
  Quote('One important key to success is self-confidence. An important '
      'key to self-confidence is preparation.', 'Arthur Ashe'),
  Quote('Success is a journey, not a destination. The doing is often '
      'more important than the outcome.', 'Arthur Ashe'),
  Quote('I fear not the man who has practiced 10,000 kicks once, but I '
      'fear the man who has practiced one kick 10,000 times.', 'Bruce Lee'),
  Quote('Long-term consistency trumps short-term intensity.', 'Bruce Lee'),
  Quote('A goal is not always meant to be reached; it often serves '
      'simply as something to aim at.', 'Bruce Lee'),
  Quote('Adapt what is useful, reject what is useless, and add what is '
      'specifically your own.', 'Bruce Lee'),
  Quote('Be water, my friend.', 'Bruce Lee'),
  Quote('Knowing is not enough, we must apply. Willing is not enough, we '
      'must do.', 'Bruce Lee'),
  Quote('If you spend too much time thinking about a thing, you\'ll '
      'never get it done.', 'Bruce Lee'),
  Quote('Do not pray for an easy life, pray for the strength to endure a '
      'difficult one.', 'Bruce Lee'),
  Quote('The successful warrior is the average man, with laser-like '
      'focus.', 'Bruce Lee'),
  Quote('Concentration is the root of all the higher abilities in man.',
      'Bruce Lee'),
  Quote('Focus is a matter of deciding what things you\'re not going to '
      'do.', 'John Carmack'),
  Quote('The main thing is to keep the main thing the main thing.',
      'Stephen Covey'),
  Quote('Begin with the end in mind.', 'Stephen Covey'),
  Quote('Put first things first.', 'Stephen Covey'),
  Quote('I am not a product of my circumstances. I am a product of my '
      'decisions.', 'Stephen Covey'),
  Quote('Sharpen the saw: preserve and enhance the greatest asset you '
      'have — you.', 'Stephen Covey'),
  Quote('Most of us spend too much time on what is urgent and not '
      'enough time on what is important.', 'Stephen Covey'),
  Quote('You can\'t build a reputation on what you are going to do.',
      'Henry Ford'),
  Quote('Obstacles are those frightful things you see when you take '
      'your eyes off your goal.', 'Henry Ford'),
  Quote('Nothing is particularly hard if you divide it into small jobs.',
      'Henry Ford'),
  Quote('When everything seems to be going against you, remember that '
      'the airplane takes off against the wind, not with it.', 'Henry Ford'),
  Quote('Vision without execution is just hallucination.',
      'Henry Ford (attributed)'),
  Quote('Chop your own wood and it will warm you twice.',
      'Henry Ford (attributed)'),
  Quote('Quality means doing it right when no one is looking.',
      'Henry Ford'),
  Quote('If everyone is moving forward together, then success takes '
      'care of itself.', 'Henry Ford'),
  Quote('Stay hungry, stay foolish.', 'Steve Jobs'),
  Quote('The people who are crazy enough to think they can change the '
      'world are the ones who do.', 'Steve Jobs'),
  Quote('Your time is limited, so don\'t waste it living someone else\'s '
      'life.', 'Steve Jobs'),
  Quote('The only way to do great work is to love what you do.',
      'Steve Jobs'),
  Quote('Details matter, it\'s worth waiting to get it right.',
      'Steve Jobs'),
  Quote('Deciding what not to do is as important as deciding what to '
      'do.', 'Steve Jobs'),
  Quote('It is not enough to be busy; so are the ants. The question is: '
      'what are we busy about?', 'Henry David Thoreau'),
  Quote('Success usually comes to those who are too busy to be looking '
      'for it.', 'Henry David Thoreau'),
  Quote('Go confidently in the direction of your dreams. Live the life '
      'you have imagined.', 'Henry David Thoreau'),
  Quote('What you get by achieving your goals is not as important as '
      'what you become by achieving your goals.', 'Henry David Thoreau '
      '(attributed)'),
  Quote('Never put off till tomorrow what may be done day after '
      'tomorrow just as well.', 'Mark Twain'),
  Quote('Continuous improvement is better than delayed perfection.',
      'Mark Twain'),
  Quote('The two most important days in your life are the day you are '
      'born and the day you find out why.', 'Mark Twain (attributed)'),
  Quote('Courage is resistance to fear, mastery of fear — not absence '
      'of fear.', 'Mark Twain'),
  Quote('Twenty years from now you will be more disappointed by the '
      'things you didn\'t do than by the ones you did do.',
      'Mark Twain (attributed)'),
  Quote('Give me six hours to chop down a tree and I will spend the '
      'first four sharpening the axe.', 'Abraham Lincoln (attributed)'),
  Quote('I am a slow walker, but I never walk back.', 'Abraham Lincoln'),
  Quote('The best way to predict your future is to create it.',
      'Abraham Lincoln (attributed)'),
  Quote('Always bear in mind that your own resolution to succeed is '
      'more important than any other.', 'Abraham Lincoln'),
  Quote('Discipline is the bridge between goals and accomplishment.',
      'Jim Rohn'),
  Quote('Motivation is what gets you started. Habit is what keeps you '
      'going.', 'Jim Rohn'),
  Quote('You must either modify your dreams or magnify your skills.',
      'Jim Rohn'),
  Quote('Happiness is not something you postpone for the future; it is '
      'something you design for the present.', 'Jim Rohn'),
  Quote('Don\'t wish it were easier, wish you were better.', 'Jim Rohn'),
  Quote('If you really want to do something, you\'ll find a way. If you '
      'don\'t, you\'ll find an excuse.', 'Jim Rohn'),
  Quote('Formal education will make you a living; self-education will '
      'make you a fortune.', 'Jim Rohn'),
  Quote('We must all suffer one of two things: the pain of discipline '
      'or the pain of regret.', 'Jim Rohn'),
  Quote('Make measurable progress in reasonable time.', 'Jim Rohn'),
  Quote('The few who do are the envy of the many who only watch.',
      'Jim Rohn'),
  Quote('Setting goals is the first step in turning the invisible into '
      'the visible.', 'Tony Robbins'),
  Quote('It\'s not what we do once in a while that shapes our lives, '
      'but what we do consistently.', 'Tony Robbins'),
  Quote('The path to success is to take massive, determined action.',
      'Tony Robbins'),
  Quote('In essence, if we want to direct our lives, we must take '
      'control of our consistent actions.', 'Tony Robbins'),
  Quote('People who succeed have momentum.', 'Tony Robbins'),
  Quote('Where focus goes, energy flows.', 'Tony Robbins'),
  Quote('A real decision is measured by the fact that you\'ve taken a '
      'new action.', 'Tony Robbins'),
  Quote('If you do what you\'ve always done, you\'ll get what you\'ve '
      'always gotten.', 'Tony Robbins'),
  Quote('Knowledge is not power. Knowledge is only potential power. '
      'Action is power.', 'Tony Robbins'),
  Quote('The secret of success is learning how to use pain and pleasure '
      'instead of having pain and pleasure use you.', 'Tony Robbins'),
  Quote('Every strike brings me closer to the next home run.',
      'Babe Ruth'),
  Quote('It\'s hard to beat a person who never gives up.', 'Babe Ruth'),
  Quote('Never let the fear of striking out keep you from playing the '
      'game.', 'Babe Ruth'),
  Quote('Yesterday\'s home runs don\'t win today\'s games.', 'Babe Ruth'),
  Quote('You just can\'t beat the person who won\'t give up.', 'Babe Ruth'),
  Quote('Age is no barrier. It\'s a limitation you put on your mind.',
      'Jackie Joyner-Kersee'),
  Quote('The medals don\'t mean anything and the glory doesn\'t last. '
      'It\'s all about your happiness.', 'Jackie Joyner-Kersee'),
  Quote('I maintained my edge by always being a student; you will '
      'always have something new to learn.', 'Jackie Joyner-Kersee'),
  Quote('Gold medals aren\'t really made of gold. They\'re made of '
      'sweat, determination, and a hard-to-find alloy called guts.',
      'Dan Gable'),
  Quote('More enduringly than any other sport, wrestling teaches '
      'self-control and pride.', 'Dan Gable'),
  Quote('If it doesn\'t challenge you, it won\'t change you.',
      'Fred DeVito'),
  Quote('What hurts today makes you stronger tomorrow.', 'Jay Cutler'),
  Quote('The clock is ticking. Are you becoming the person you want to '
      'be?', 'Greg Plitt'),
  Quote('Success trains. Failure complains.'),
  Quote('The body achieves what the mind believes.'),
  Quote('A one-hour workout is 4% of your day. No excuses.'),
  Quote('You don\'t find willpower, you create it.'),
  Quote('Wake up with determination. Go to bed with satisfaction.'),
  Quote('It never gets easier. You just get stronger.'),
  Quote('Push yourself, because no one else is going to do it for you.'),
  Quote('Great things never come from comfort zones.'),
  Quote('Your only limit is you.'),
  Quote('Prove them wrong — especially the voice in your head.'),
  Quote('Do something today that your future self will thank you for.'),
  Quote('Success doesn\'t come to you. You go to it.'),
  Quote('Don\'t stop when you\'re tired. Stop when you\'re done.'),
  Quote('It always feels too early until it\'s suddenly too late.'),
  Quote('The comeback is always stronger than the setback.'),
  Quote('Fall in love with the process and the results will come.'),
  Quote('Champions are made when no one is watching.'),
  Quote('Every pro was once an amateur. Every expert was once a '
      'beginner.'),
  Quote('Start now. Optimize later.'),
  Quote('An imperfect start beats a perfect plan.'),
  Quote('You can\'t edit a blank page.', 'Jodi Picoult (adapted)'),
  Quote('Write drunk on enthusiasm; edit sober with discipline.'),
  Quote('Books aren\'t written — they\'re rewritten.', 'Michael Crichton'),
  Quote('The scariest moment is always just before you start.',
      'Stephen King'),
  Quote('Talent is cheaper than table salt. What separates the talented '
      'individual from the successful one is a lot of hard work.',
      'Stephen King'),
  Quote('You can, you should, and if you\'re brave enough to start, you '
      'will.', 'Stephen King'),
  Quote('Start writing, no matter what. The water does not flow until '
      'the faucet is turned on.', 'Louis L\'Amour'),
  Quote('There will come a time when you believe everything is '
      'finished. That will be the beginning.', 'Louis L\'Amour'),
  Quote('Victory is won not in miles but in inches. Win a little now, '
      'hold your ground, and later, win a little more.', 'Louis L\'Amour'),
  Quote('Up to a point a person\'s life is shaped by environment, '
      'heredity, and changes in the world. Then there comes a time when '
      'it lies within their grasp to shape the clay of their life into '
      'the sort of thing they wish it to be.', 'Louis L\'Amour'),
  Quote('The way to get things done is not to mind who gets the credit '
      'for doing them.', 'Benjamin Jowett'),
  Quote('It is amazing what you can accomplish if you do not care who '
      'gets the credit.', 'Harry S. Truman (attributed)'),
  Quote('Imperfect action is better than perfect inaction.',
      'Harry S. Truman'),
  Quote('In reading the lives of great men, I found that the first '
      'victory they won was over themselves.', 'Harry S. Truman'),
  Quote('Not all readers are leaders, but all leaders are readers.',
      'Harry S. Truman'),
  Quote('A goal without a plan is just a wish.',
      'Antoine de Saint-Exupéry'),
  Quote('Perfection is achieved, not when there is nothing more to add, '
      'but when there is nothing left to take away.',
      'Antoine de Saint-Exupéry'),
  Quote('If you want to build a ship, don\'t drum up the men to gather '
      'wood... teach them to yearn for the vast and endless sea.',
      'Antoine de Saint-Exupéry (adapted)'),
  Quote('True happiness comes from the joy of deeds well done, the zest '
      'of creating things new.', 'Antoine de Saint-Exupéry'),
  Quote('Make your life a dream, and a dream a reality.',
      'Antoine de Saint-Exupéry'),
  Quote('Plans are nothing; planning is everything.',
      'Dwight D. Eisenhower'),
  Quote('What is important is seldom urgent and what is urgent is '
      'seldom important.', 'Dwight D. Eisenhower (attributed)'),
  Quote('Pessimism never won any battle.', 'Dwight D. Eisenhower'),
  Quote('Accomplishment will prove to be a journey, not a destination.',
      'Dwight D. Eisenhower'),
  Quote('Optimism is the faith that leads to achievement. Nothing can '
      'be done without hope and confidence.', 'Helen Keller'),
  Quote('Keep your face to the sunshine and you cannot see a shadow.',
      'Helen Keller'),
  Quote('Alone we can do so little; together we can do so much.',
      'Helen Keller'),
  Quote('Character cannot be developed in ease and quiet. Only through '
      'experience of trial and suffering can the soul be strengthened.',
      'Helen Keller'),
  Quote('Life is either a daring adventure or nothing at all.',
      'Helen Keller'),
  Quote('Although the world is full of suffering, it is also full of '
      'the overcoming of it.', 'Helen Keller'),
  Quote('When one door of happiness closes, another opens.',
      'Helen Keller'),
  Quote('Never bend your head. Always hold it high. Look the world '
      'straight in the eye.', 'Helen Keller'),
  Quote('We can do anything we want to if we stick to it long enough.',
      'Helen Keller'),
  Quote('The unexamined life is not worth living.', 'Socrates'),
  Quote('The secret of change is to focus all of your energy not on '
      'fighting the old, but on building the new.',
      'Socrates (attributed)'),
  Quote('To move the world we must first move ourselves.', 'Socrates'),
  Quote('Employ your time in improving yourself by other men\'s '
      'writings.', 'Socrates'),
  Quote('Falling down is not a failure. Failure comes when you stay '
      'where you have fallen.', 'Socrates'),
  Quote('He who is not a good servant will not be a good master.',
      'Plato'),
  Quote('The beginning is the most important part of the work.', 'Plato'),
  Quote('Never discourage anyone who continually makes progress, no '
      'matter how slow.', 'Plato (attributed)'),
  Quote('Excellence is not a gift, but a skill that takes practice.',
      'Plato'),
  Quote('Good actions give strength to ourselves and inspire good '
      'actions in others.', 'Plato'),
  Quote('Pleasure in the job puts perfection in the work.', 'Aristotle'),
  Quote('Through discipline comes freedom.', 'Aristotle'),
  Quote('It is during our darkest moments that we must focus to see '
      'the light.', 'Aristotle (attributed)'),
  Quote('Hope is a waking dream.', 'Aristotle'),
  Quote('First, have a definite, clear practical ideal; a goal, an '
      'objective.', 'Aristotle'),
  Quote('You will never do anything in this world without courage.',
      'Aristotle'),
  Quote('The energy of the mind is the essence of life.', 'Aristotle'),
  Quote('Knowing yourself is the beginning of all wisdom.', 'Aristotle'),
  Quote('When you know better, you do better.', 'Maya Angelou'),
  Quote('If you don\'t like something, change it. If you can\'t change '
      'it, change your attitude.', 'Maya Angelou'),
  Quote('You may encounter many defeats, but you must not be defeated.',
      'Maya Angelou'),
  Quote('All great achievements require time.', 'Maya Angelou'),
  Quote('We may encounter many defeats but we must not be defeated.',
      'Maya Angelou'),
  Quote('Ask for what you want and be prepared to get it.',
      'Maya Angelou'),
  Quote('Success is liking yourself, liking what you do, and liking how '
      'you do it.', 'Maya Angelou'),
  Quote('Try to be a rainbow in someone\'s cloud.', 'Maya Angelou'),
  Quote('Each day brings a chance to begin again.'),
  Quote('Today is your opportunity to build the tomorrow you want.',
      'Ken Poirot'),
  Quote('Every morning brings new potential.'),
  Quote('Morning routines are the anchor of a productive day.'),
  Quote('A good plan today beats a perfect plan tomorrow.'),
  Quote('Ticking one box today beats planning ten for tomorrow.'),
  Quote('Streaks are built one honest day at a time.'),
  Quote('Missing once is an accident. Missing twice is the start of a '
      'new habit.', 'James Clear'),
  Quote('Never miss twice.', 'James Clear'),
  Quote('You should be far more concerned with your current trajectory '
      'than with your current results.', 'James Clear'),
  Quote('Goals are good for setting a direction, but systems are best '
      'for making progress.', 'James Clear'),
  Quote('Time magnifies the margin between success and failure.',
      'James Clear'),
  Quote('Success is the product of daily habits — not once-in-a-'
      'lifetime transformations.', 'James Clear'),
  Quote('Small habits don\'t add up. They compound.', 'James Clear'),
  Quote('Be the designer of your world and not merely the consumer of '
      'it.', 'James Clear'),
  Quote('The most practical way to change who you are is to change '
      'what you do.', 'James Clear'),
  Quote('Improve by 1% a day, and in a year you\'ll be 37 times '
      'better.', 'James Clear'),
  Quote('What is not started today is never finished tomorrow.',
      'Johann Wolfgang von Goethe'),
  Quote('Knowing is not enough; we must apply. Wishing is not enough; '
      'we must do.', 'Johann Wolfgang von Goethe'),
  Quote('Whatever you can do or dream you can, begin it. Boldness has '
      'genius, power and magic in it.',
      'Johann Wolfgang von Goethe (attributed)'),
  Quote('Cease endlessly striving for what you would like to do and '
      'learn to love what must be done.', 'Johann Wolfgang von Goethe'),
  Quote('Thinking is easy, acting is difficult, and to put one\'s '
      'thoughts into action is the most difficult thing in the world.',
      'Johann Wolfgang von Goethe'),
  Quote('Daring ideas are like chessmen moved forward; they may be '
      'beaten, but they may start a winning game.',
      'Johann Wolfgang von Goethe'),
  Quote('He who moves not forward, goes backward.',
      'Johann Wolfgang von Goethe'),
  Quote('Nothing is worth more than this day.',
      'Johann Wolfgang von Goethe'),
  Quote('Only put off until tomorrow what you are willing to die having '
      'left undone.', 'Pablo Picasso'),
  Quote('I am always doing that which I cannot do, in order that I may '
      'learn how to do it.', 'Pablo Picasso'),
  Quote('Every child is an artist. The problem is how to remain an '
      'artist once we grow up.', 'Pablo Picasso'),
  Quote('Learn the rules like a pro, so you can break them like an '
      'artist.', 'Pablo Picasso'),
  Quote('Others have seen what is and asked why. I have seen what could '
      'be and asked why not.', 'Pablo Picasso'),
  Quote('If people knew how hard I worked to get my mastery, it '
      'wouldn\'t seem so wonderful at all.', 'Michelangelo'),
  Quote('The greater danger for most of us lies not in setting our aim '
      'too high and falling short, but in setting our aim too low and '
      'achieving our mark.', 'Michelangelo'),
  Quote('I am still learning.', 'Michelangelo'),
  Quote('Genius is eternal patience.', 'Michelangelo'),
  Quote('Trifles make perfection, and perfection is no trifle.',
      'Michelangelo'),
  Quote('It is not the strongest of the species that survives, nor the '
      'most intelligent, but the one most responsive to change.',
      'Leon Megginson (on Darwin)'),
  Quote('A man who dares to waste one hour of time has not discovered '
      'the value of life.', 'Charles Darwin'),
  Quote('In the long history of humankind, those who learned to '
      'collaborate and improvise most effectively have prevailed.',
      'Charles Darwin (attributed)'),
  Quote('Intelligence is the ability to adapt to change.',
      'Stephen Hawking'),
  Quote('However difficult life may seem, there is always something '
      'you can do and succeed at.', 'Stephen Hawking'),
  Quote('While there\'s life, there is hope.', 'Stephen Hawking'),
  Quote('Look up at the stars and not down at your feet.',
      'Stephen Hawking'),
  Quote('Work hard in silence, let your success be the noise.',
      'Frank Ocean'),
  Quote('Work gives you meaning and purpose and life is empty without '
      'it.', 'Stephen Hawking'),
  Quote('Life would be tragic if it weren\'t funny.', 'Stephen Hawking'),
  Quote('Try to make sense of what you see, and wonder about what '
      'makes the universe exist. Be curious.', 'Stephen Hawking'),
  Quote('Logic will get you from A to B. Imagination will take you '
      'everywhere.', 'Albert Einstein'),
  Quote('Life is like riding a bicycle. To keep your balance, you must '
      'keep moving.', 'Albert Einstein'),
  Quote('In the middle of difficulty lies opportunity.',
      'Albert Einstein'),
  Quote('It\'s not that I\'m so smart, it\'s just that I stay with '
      'problems longer.', 'Albert Einstein'),
  Quote('A person who never made a mistake never tried anything new.',
      'Albert Einstein'),
  Quote('Strive not to be a success, but rather to be of value.',
      'Albert Einstein'),
  Quote('Once we accept our limits, we go beyond them.',
      'Albert Einstein'),
  Quote('Learn from yesterday, live for today, hope for tomorrow.',
      'Albert Einstein'),
  Quote('The only source of knowledge is experience.', 'Albert Einstein'),
  Quote('Weakness of attitude becomes weakness of character.',
      'Albert Einstein'),
  Quote('Nothing in life is to be feared, it is only to be understood.',
      'Marie Curie'),
  Quote('I was taught that the way of progress was neither swift nor '
      'easy.', 'Marie Curie'),
  Quote('Have no fear of perfection; you\'ll never reach it.',
      'Marie Curie (attributed)'),
  Quote('Be less curious about people and more curious about ideas.',
      'Marie Curie'),
  Quote('Life is not easy for any of us. But what of that? We must '
      'have perseverance and above all confidence in ourselves.',
      'Marie Curie'),
  Quote('One never notices what has been done; one can only see what '
      'remains to be done.', 'Marie Curie'),
  Quote('If I have seen further it is by standing on the shoulders of '
      'giants.', 'Isaac Newton'),
  Quote('Tact is the art of making a point without making an enemy.',
      'Isaac Newton'),
  Quote('What we know is a drop, what we don\'t know is an ocean.',
      'Isaac Newton'),
  Quote('Truth is ever to be found in simplicity, and not in the '
      'multiplicity and confusion of things.', 'Isaac Newton'),
  Quote('An investment in knowledge pays the best interest.',
      'Benjamin Franklin'),
  Quote('By failing to prepare, you are preparing to fail.',
      'Benjamin Franklin'),
  Quote('Well done is better than well said.', 'Benjamin Franklin'),
  Quote('Never leave that till tomorrow which you can do today.',
      'Benjamin Franklin'),
  Quote('Early to bed and early to rise makes a man healthy, wealthy '
      'and wise.', 'Benjamin Franklin'),
  Quote('Diligence is the mother of good luck.', 'Benjamin Franklin'),
  Quote('Little strokes fell great oaks.', 'Benjamin Franklin'),
  Quote('Never confuse motion with action.', 'Benjamin Franklin'),
  Quote('Tell me and I forget. Teach me and I remember. Involve me and '
      'I learn.', 'Benjamin Franklin (attributed)'),
  Quote('Hide not your talents, they for use were made. What\'s a '
      'sundial in the shade?', 'Benjamin Franklin'),
  Quote('One today is worth two tomorrows.', 'Benjamin Franklin'),
  Quote('Resolve to perform what you ought; perform without fail what '
      'you resolve.', 'Benjamin Franklin'),
  Quote('The best portion of a good man\'s life: his little, nameless, '
      'unremembered acts of kindness and love.', 'William Wordsworth'),
  Quote('Fill your paper with the breathings of your heart.',
      'William Wordsworth'),
  Quote('To begin, begin.', 'William Wordsworth'),
  Quote('Habit rules the unreflecting herd.', 'William Wordsworth'),
  Quote('Not in Utopia — subterranean fields — or some secreted '
      'island, Heaven knows where! But in the very world, which is the '
      'world of all of us — the place where, in the end, we find our '
      'happiness, or not at all!', 'William Wordsworth'),
  Quote('Nothing great was ever achieved without enthusiasm.',
      'Ralph Waldo Emerson'),
  Quote('Always do what you are afraid to do.', 'Ralph Waldo Emerson'),
  Quote('Every artist was first an amateur.', 'Ralph Waldo Emerson'),
  Quote('Life is a journey, not a destination.',
      'Ralph Waldo Emerson (attributed)'),
  Quote('Make the most of yourself, for that is all there is of you.',
      'Ralph Waldo Emerson'),
  Quote('That which we persist in doing becomes easier for us to do.',
      'Ralph Waldo Emerson (attributed)'),
  Quote('Self-trust is the first secret of success.',
      'Ralph Waldo Emerson'),
  Quote('The reward of a thing well done is having done it.',
      'Ralph Waldo Emerson'),
  Quote('Big jobs usually go to the men who prove their ability to '
      'outgrow small ones.', 'Ralph Waldo Emerson'),
  Quote('The only way to have a friend is to be one.',
      'Ralph Waldo Emerson'),
  Quote('Hitch your wagon to a star.', 'Ralph Waldo Emerson'),
  Quote('When it is dark enough, you can see the stars.',
      'Ralph Waldo Emerson'),
  Quote('Tomorrow is a new day; begin it well and serenely.',
      'Ralph Waldo Emerson'),
  Quote('An ounce of action is worth a ton of theory.',
      'Ralph Waldo Emerson (attributed)'),
  Quote('Enthusiasm is the mother of effort, and without it nothing '
      'great was ever achieved.', 'Ralph Waldo Emerson'),
  Quote('Water the seeds you want to grow.'),
  Quote('You reap what you sow — so sow daily.'),
  Quote('Plant patience, harvest peace.'),
  Quote('Even the tallest bamboo grows one ring at a time.'),
  Quote('A garden is never finished — and neither are you. Keep '
      'tending.'),
  Quote('Rain or shine, the farmer shows up. So can you.'),
  Quote('Strong roots grow in silence, long before the tree is seen.'),
  Quote('Bloom where you are planted.'),
  Quote('The bamboo that bends is stronger than the oak that resists.',
      'Japanese proverb'),
  Quote('Vision without action is a daydream. Action without vision is '
      'a nightmare.', 'Japanese proverb'),
  Quote('Beginning is easy — continuing is hard.', 'Japanese proverb'),
  Quote('Even dust, when piled up, becomes a mountain.',
      'Japanese proverb'),
  Quote('One kind word can warm three winter months.',
      'Japanese proverb'),
  Quote('The day you decide to do it is your lucky day.',
      'Japanese proverb'),
  Quote('Continuance is power.', 'Japanese proverb'),
  Quote('If you get on the wrong train, get off at the nearest '
      'station; the longer you stay, the more expensive the return '
      'trip.', 'Japanese proverb'),
  Quote('A frog in a well does not know the great sea — keep '
      'exploring.', 'Japanese proverb'),
  Quote('When the character of a man is not clear to you, look at his '
      'habits.', 'Japanese proverb (adapted)'),
  Quote('However long the night, the dawn will break.',
      'African proverb'),
  Quote('If you want to go fast, go alone. If you want to go far, go '
      'together.', 'African proverb'),
  Quote('Smooth seas do not make skillful sailors.', 'African proverb'),
  Quote('The best way to eat an elephant is one bite at a time.',
      'African proverb'),
  Quote('Wisdom is like a baobab tree; no one individual can embrace '
      'it.', 'African proverb'),
  Quote('Rain does not fall on one roof alone.', 'African proverb'),
  Quote('Tomorrow belongs to the people who prepare for it today.',
      'African proverb'),
  Quote('Little by little, a little becomes a lot.', 'Tanzanian proverb'),
  Quote('When you pray, move your feet.', 'African proverb'),
  Quote('He who learns, teaches.', 'Ethiopian proverb'),
  Quote('A man who uses force is afraid of reasoning.', 'Kenyan proverb'),
  Quote('Patience can cook a stone.', 'African proverb'),
  Quote('The sun does not forget a village just because it is small.',
      'African proverb'),
  Quote('Do not look where you fell, but where you slipped.',
      'African proverb'),
  Quote('No matter how long the winter, spring is sure to follow.',
      'Proverb'),
  Quote('A smooth path never made a strong traveler.'),
  Quote('Storms make trees take deeper roots.', 'Dolly Parton'),
  Quote('If you want the rainbow, you gotta put up with the rain.',
      'Dolly Parton'),
  Quote('The way I see it, if you want the rainbow, you have to '
      'welcome the rain first.'),
  Quote('You\'ll never do a whole lot unless you\'re brave enough to '
      'try.', 'Dolly Parton'),
  Quote('Find out who you are and do it on purpose.', 'Dolly Parton'),
  Quote('We cannot direct the wind, but we can adjust the sails.',
      'Dolly Parton (attributed)'),
  Quote('Don\'t get so busy making a living that you forget to make a '
      'life.', 'Dolly Parton'),
  Quote('You are braver than you believe, stronger than you seem, and '
      'smarter than you think.', 'A. A. Milne'),
  Quote('Rivers know this: there is no hurry. We shall get there some '
      'day.', 'A. A. Milne'),
  Quote('You can\'t stay in your corner of the Forest waiting for '
      'others to come to you. You have to go to them sometimes.',
      'A. A. Milne'),
  Quote('It is more fun to talk with someone who doesn\'t use long, '
      'difficult words but rather short, easy words like "What about '
      'lunch?"', 'A. A. Milne'),
  Quote('Weeds are flowers too, once you get to know them.',
      'A. A. Milne'),
  Quote('The nicest thing about the rain is that it always stops. '
      'Eventually.', 'A. A. Milne'),
  Quote('Never give up, for that is just the place and time that the '
      'tide will turn.', 'Harriet Beecher Stowe'),
  Quote('When you get into a tight place and everything goes against '
      'you, never give up then, for that is just the place and time '
      'that the tide will turn.', 'Harriet Beecher Stowe'),
  Quote('To be really great in little things, to be truly noble and '
      'heroic in the insipid details of everyday life, is a virtue so '
      'rare as to be worthy of canonization.', 'Harriet Beecher Stowe'),
  Quote('The past, the present and the future are really one: they '
      'are today.', 'Harriet Beecher Stowe'),
  Quote('It\'s always too early to quit.', 'Norman Vincent Peale'),
  Quote('Change your thoughts and you change your world.',
      'Norman Vincent Peale'),
  Quote('Shoot for the moon. Even if you miss, you\'ll land among the '
      'stars.', 'Norman Vincent Peale'),
  Quote('Believe in yourself! Have faith in your abilities!',
      'Norman Vincent Peale'),
  Quote('Enthusiasm makes the difference.', 'Norman Vincent Peale'),
  Quote('Action is a great restorer and builder of confidence.',
      'Norman Vincent Peale'),
  Quote('Empty pockets never held anyone back. Only empty heads and '
      'empty hearts can do that.', 'Norman Vincent Peale'),
  Quote('Stand up to your obstacles and do something about them. You '
      'will find that they haven\'t half the strength you think they '
      'have.', 'Norman Vincent Peale'),
  Quote('Watch your thoughts, they become your words; watch your '
      'words, they become your actions.', 'Lao Tzu (attributed)'),
  Quote('When I let go of what I am, I become what I might be.',
      'Lao Tzu'),
  Quote('Nature does not hurry, yet everything is accomplished.',
      'Lao Tzu'),
  Quote('Do the difficult things while they are easy and do the great '
      'things while they are small.', 'Lao Tzu'),
  Quote('He who conquers others is strong; he who conquers himself is '
      'mighty.', 'Lao Tzu'),
  Quote('A good traveler has no fixed plans and is not intent on '
      'arriving.', 'Lao Tzu'),
  Quote('Mastering others is strength. Mastering yourself is true '
      'power.', 'Lao Tzu'),
  Quote('Great acts are made up of small deeds.', 'Lao Tzu'),
  Quote('If you do not change direction, you may end up where you are '
      'heading.', 'Lao Tzu'),
  Quote('To see things in the seed, that is genius.', 'Lao Tzu'),
  Quote('Respond intelligently even to unintelligent treatment.',
      'Lao Tzu'),
  Quote('The flame that burns twice as bright burns half as long — '
      'pace yourself.', 'Lao Tzu (adapted)'),
  Quote('Choose a job you love, and you will never have to work a day '
      'in your life.', 'Confucius (attributed)'),
  Quote('When it is obvious that the goals cannot be reached, don\'t '
      'adjust the goals, adjust the action steps.', 'Confucius'),
  Quote('Real knowledge is to know the extent of one\'s ignorance.',
      'Confucius'),
  Quote('I hear and I forget. I see and I remember. I do and I '
      'understand.', 'Confucius (attributed)'),
  Quote('The superior man is modest in his speech, but exceeds in his '
      'actions.', 'Confucius'),
  Quote('Wherever you go, go with all your heart.', 'Confucius'),
  Quote('Everything has beauty, but not everyone sees it.', 'Confucius'),
  Quote('They must often change who would be constant in happiness or '
      'wisdom.', 'Confucius'),
  Quote('Study the past if you would define the future.', 'Confucius'),
  Quote('To be wronged is nothing, unless you continue to remember '
      'it.', 'Confucius'),
  Quote('The will to win, the desire to succeed, the urge to reach '
      'your full potential — these are the keys that will unlock the '
      'door to personal excellence.', 'Confucius (attributed)'),
  Quote('Life is really simple, but we insist on making it '
      'complicated.', 'Confucius'),
  Quote('Better a diamond with a flaw than a pebble without.',
      'Confucius'),
  Quote('If you look into your own heart, and you find nothing wrong '
      'there, what is there to worry about? What is there to fear?',
      'Confucius'),
  Quote('Success depends upon previous preparation, and without such '
      'preparation there is sure to be failure.', 'Confucius'),
  Quote('You cannot cross the sea merely by standing and staring at '
      'the water.', 'Rabindranath Tagore'),
  Quote('Let your life lightly dance on the edges of Time like dew on '
      'the tip of a leaf.', 'Rabindranath Tagore'),
  Quote('Faith is the bird that feels the light when the dawn is '
      'still dark.', 'Rabindranath Tagore'),
  Quote('If you cry because the sun has gone out of your life, your '
      'tears will prevent you from seeing the stars.',
      'Rabindranath Tagore'),
  Quote('Do not say, "It is morning," and dismiss it with a name of '
      'yesterday. See it for the first time as a newborn child that '
      'has no name.', 'Rabindranath Tagore'),
  Quote('The butterfly counts not months but moments, and has time '
      'enough.', 'Rabindranath Tagore'),
  Quote('You can\'t go back and change the beginning, but you can '
      'start where you are and change the ending.',
      'C.S. Lewis (attributed)'),
  Quote('Isn\'t it funny how day by day nothing changes, but when you '
      'look back everything is different?', 'C.S. Lewis'),
  Quote('There are far, far better things ahead than any we leave '
      'behind.', 'C.S. Lewis'),
  Quote('You are never too old to set another goal or to dream a new '
      'dream.', 'C.S. Lewis (attributed)'),
  Quote('Courage, dear heart.', 'C.S. Lewis'),
  Quote('Getting over a painful experience is much like crossing '
      'monkey bars. You have to let go at some point in order to move '
      'forward.', 'C.S. Lewis (attributed)'),
  Quote('Failures are finger posts on the road to achievement.',
      'C.S. Lewis'),
  Quote('The salvation of this human world lies nowhere else than in '
      'the human heart.', 'Václav Havel'),
  Quote('Hope is not the conviction that something will turn out '
      'well, but the certainty that something makes sense, regardless '
      'of how it turns out.', 'Václav Havel'),
  Quote('Work for something because it is good, not just because it '
      'stands a chance to succeed.', 'Václav Havel'),
  Quote('Just keep swimming.', 'Finding Nemo'),
  Quote('Adventure is out there!', 'Up'),
  Quote('The flower that blooms in adversity is the most rare and '
      'beautiful of all.', 'Mulan'),
  Quote('Our fate lives within us; you only have to be brave enough '
      'to see it.', 'Brave'),
  Quote('Even miracles take a little time.', 'Cinderella'),
  Quote('Oh yes, the past can hurt. But the way I see it, you can '
      'either run from it or learn from it.', 'The Lion King'),
  Quote('Hakuna Matata — but after you tick today\'s tasks.'),
  Quote('Every day is a fresh start — the calendar just makes it '
      'official.'),
  Quote('Your habits are the architecture of your future self.'),
  Quote('Ten minutes of doing beats ten hours of doubting.'),
  Quote('The task you avoid costs more energy than the task you do.'),
  Quote('Finish something small before noon and the day is already a '
      'win.'),
  Quote('Momentum loves a moving target — start rolling.'),
  Quote('Nobody regrets the workout, the walk, or the page they '
      'wrote.'),
  Quote('Your streak doesn\'t care about your mood — show up anyway.'),
  Quote('Tired is temporary. Quit is permanent.'),
  Quote('You don\'t need more time, you need fewer distractions.'),
  Quote('Focus on the step in front of you, not the whole staircase.'),
  Quote('Count your wins before you count your worries.'),
  Quote('Comparison stalls progress; yesterday-you is the only fair '
      'rival.'),
  Quote('Beat yesterday. That\'s the whole game.'),
  Quote('The checkbox is small; the identity it builds is not.'),
  Quote('Keep promises to yourself first.'),
  Quote('Self-discipline is self-respect in action.'),
  Quote('A short note today is a gift to future you.'),
  Quote('Reflection turns experience into progress.'),
  Quote('What you practice grows stronger.'),
  Quote('Turn "I have to" into "I get to".'),
  Quote('Gratitude turns what we have into enough.'),
  Quote('Calm mind, steady hands, daily wins.'),
  Quote('Breathe. Begin. Repeat tomorrow.'),
  Quote('The second week is where champions are made.'),
  Quote('Day 21: where a chore quietly becomes a character trait.'),
  Quote('You survived every hard day so far — a perfect record.'),
  Quote('Make rest part of the plan, not a failure of it.'),
  Quote('Recovery is training too.'),
  Quote('Slow is smooth, smooth is fast.'),
  Quote('Direction over speed; consistency over intensity.'),
  Quote('When motivation fades, let routine carry you.'),
  Quote('Routines free the mind for what matters.'),
  Quote('Simplicity is the soul of efficiency.', 'Austin Freeman'),
  Quote('It is quality rather than quantity that matters.', 'Seneca'),
  Quote('Make each day your masterpiece.', 'John Wooden'),
  Quote('Do not let what you cannot do interfere with what you can '
      'do.', 'John Wooden'),
  Quote('Success is peace of mind which is a direct result of knowing '
      'you did your best.', 'John Wooden'),
  Quote('Little things make big things happen.', 'John Wooden'),
  Quote('Don\'t measure yourself by what you have accomplished, but '
      'by what you should have accomplished with your ability.',
      'John Wooden'),
  Quote('Failing to prepare is preparing to fail.', 'John Wooden'),
  Quote('Be quick, but don\'t hurry.', 'John Wooden'),
  Quote('The true test of a man\'s character is what he does when no '
      'one is watching.', 'John Wooden'),
  Quote('Flexibility is the key to stability.', 'John Wooden'),
  Quote('Never mistake activity for achievement.', 'John Wooden'),
  Quote('If you don\'t have time to do it right, when will you have '
      'time to do it over?', 'John Wooden'),
  Quote('Ability may get you to the top, but it takes character to '
      'keep you there.', 'John Wooden'),
  Quote('Things turn out best for the people who make the best of the '
      'way things turn out.', 'John Wooden'),
  Quote('Today is the only day. Yesterday is gone.', 'John Wooden'),
  Quote('It\'s the little details that are vital. Little things make '
      'big things happen.', 'John Wooden'),
];
