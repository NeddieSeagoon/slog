"""
Implements a Discord bot using discord.py. 
Handles /subscribe <group> and posts relevant events to subscribed channels.
"""
import discord
from discord.ext import commands

class StarCitizenBot(commands.Bot):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.channel_subscriptions = {}

    async def on_ready(self):
        print(f"Logged in as {self.user}")

    @commands.slash_command(description="Subscribe this channel to a group passphrase.")
    async def subscribe(self, ctx, group_passphrase: str):
        self.channel_subscriptions[ctx.channel.id] = group_passphrase
        await ctx.respond(f"This channel is now subscribed to group: '{group_passphrase}'")

    async def handle_new_event(self, event_data: dict):
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
        # Add more event types as desired.

def create_discord_bot(token: str):
    intents = discord.Intents.default()
    bot = StarCitizenBot(command_prefix="/", intents=intents)
    return bot
