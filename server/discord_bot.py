import discord
from discord.ext import commands
from discord import app_commands

class StarCitizenBot(commands.Bot):
    def __init__(self, **kwargs):
        # We can still specify a command_prefix even if we only use slash commands.
        # It won't interfere with app commands. We'll omit it here for clarity.
        intents = discord.Intents.default()
        super().__init__(intents=intents, **kwargs)

        # Dictionary to keep track of channel -> group subscriptions
        self.channel_subscriptions = {}

    async def on_ready(self):
        print(f"Logged in as {self.user}")

    async def setup_hook(self):
        """
        Called automatically by discord.py when the bot is ready to set up.
        We register our slash (app) command here and then sync the command tree.
        """
        # Register the /subscribe command
        self.tree.add_command(self.subscribe)

        # Synchronize the command tree (registers commands with Discord)
        await self.tree.sync()
        print("Slash commands have been synchronized.")

    @app_commands.command(name="subscribe", description="Subscribe this channel to a group passphrase.")
    @app_commands.describe(group_passphrase="The group passphrase to subscribe to")
    async def subscribe(self, interaction: discord.Interaction, group_passphrase: str):
        """
        Allows a user to subscribe the current channel to the specified group.
        """
        self.channel_subscriptions[interaction.channel_id] = group_passphrase
        await interaction.response.send_message(
            f"This channel is now subscribed to group: '{group_passphrase}'"
        )

    async def handle_new_event(self, event_data: dict):
        """
        Called whenever a new event (kill, vehicle destruction, etc.) is received.
        Broadcasts messages to subscribed channels.
        """
        group = event_data.get("group")
        event_type = event_data.get("event_type")

        if event_type == "kill":
            killer = event_data.get("killer")
            victim = event_data.get("victim")
            for channel_id, subscribed_group in self.channel_subscriptions.items():
                if subscribed_group == group:
                    channel = self.get_channel(channel_id)
                    if channel:
                        await channel.send(
                            f"**Kill Event** in group '{group}': {killer} killed {victim}"
                        )

        elif event_type == "vehicle_destruction":
            player = event_data.get("player")
            vehicle = event_data.get("vehicle")
            for channel_id, subscribed_group in self.channel_subscriptions.items():
                if subscribed_group == group:
                    channel = self.get_channel(channel_id)
                    if channel:
                        await channel.send(
                            f"**Vehicle Destruction** in group '{group}': {vehicle} destroyed by {player}"
                        )

        # Add more event types as needed...

def create_discord_bot(token: str) -> StarCitizenBot:
    """
    Creates and returns an instance of StarCitizenBot, ready to be run.
    You can then call bot.run(token) on the returned object.
    """
    bot = StarCitizenBot()
    return bot
